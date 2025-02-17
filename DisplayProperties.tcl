#========== Subroutine ==========
proc DisplayProperties {inputDSNFilePath} {
	# Display R_C_Property for DSN file.
	puts "Opening DSN file..."
	
	set dsnName [file tail $inputDSNFilePath]
	set dsnPureName [file rootname $dsnName]
	set dsnDirName [file dirname $inputDSNFilePath]
	
	MenuCommand "57601" | FileDialog  "OK" $inputDSNFilePath 2 | DialogBox  "OK" "C:/BIOS/OrCADSch/DisplayProperties/Select_Project_Type.xml"
	puts "Done"
	after 2000
	
	# Export EDF file.
	puts "Creating EDF file..."
	XMATIC_CAP2EDIF $inputDSNFilePath "C:/BIOS/OrCADSch/DisplayProperties/${dsnPureName}.EDF" "C:/Cadence/SPB_23.1/tools/capture/CAP2EDI.CFG"
	puts "Done"
	after 3000
	
	# Export BOM.
	puts "Generating BOM..."
	Menu "Tools::Bill of Materials" | DialogBox  "OK" "C:/BIOS/OrCADSch/DisplayProperties/Bill_of_Materials.xml"
	set bomFileName "C:/BIOS/OrCADSch/DisplayProperties/${dsnPureName}.BOM"
	ReadFiles create readBOM $bomFileName "BOM"
	set bomList [readBOM readFile "\t"]
	set bomListLen [llength $bomList]
	after 1000
	
	# Get the reference name to display.
	puts "Collecting display reference name..."
	set displayRefList {}
	for {set i 14} {$i < $bomListLen} {incr i} {
		set rowData [lindex $bomList $i]
		set ref [lindex $rowData 0]
		set partNumber [lindex $rowData 1]
		
		if {[string length $partNumber] == 11} {
			if {[string first "SD" $partNumber] == 0 || [string first "SE" $partNumber] == 0} {
				lappend displayRefList $ref
			}
		}
	}
	
	# Processing EDF file.
	set filterEDFList [EDFCleaning "C:/BIOS/OrCADSch/DisplayProperties/${dsnPureName}.EDF"]
	set schFolderName [GetSchematicFolderName $filterEDFList]
	
	# Append coordinates by part ref with page to a dict.
	set refWithPage {}
	foreach reference $displayRefList {
		set partRef $reference
		set schPage [GetSchematicPage $filterEDFList $partRef]
		set symbolCoor [GetSymbolCoordinates $filterEDFList $partRef]
		set coorX [lindex $symbolCoor 0]
		set coorY [lindex $symbolCoor 1]
		
		set refDict {}
		dict lappend refDict $partRef $coorX
		dict lappend refDict $partRef $coorY
		
		dict lappend refWithPage $schPage $refDict
	}

	dict for {keyVar valueVar} $refWithPage {
		set schPage $keyVar
		set partRefInfo $valueVar
		set partRefPerPage [llength $partRefInfo]
		
		# Open the target page.
		SelectPMItem $schFolderName
		SelectPMItem $schPage
		OPage $schFolderName $schPage
		after 3000
		#capDisplayMessageBox "Break point.\nPress to continue." "Interrupt"
		for {set partIdx 0} {$partIdx < $partRefPerPage} {incr partIdx} {
			# Select all symbols that need to display R_C_Property in a page.
			set part [lindex $partRefInfo $partIdx]
			set attrs [lindex $part 1]
			set coorX [lindex $attrs 0]
			set coorY [lindex $attrs 1]
			
			SelectObject $coorX $coorY TRUE
		}
		DisplayRC
		Menu "File::Save"
		MenuCommand "57927"
		after 2000
	}
	# Save as
	SelectPMItem $schFolderName
	Menu "File::Save As" | FileDialog  "OK" "${dsnDirName}/${dsnPureName}_display/${dsnName}" 1
	Menu "File::close"
	Menu "File::Exit"
}

#========== Method ==========
proc EDFCleaning {edfFilePath} {
	# Only get the data we may need by prefix text.
	set startWordsKeep {"(page" "(rename " "(stringDisplay " "(cellRef " "(pt " "(transform" "(orientation "}
	set startWordsThrow {"(rename OUTER" "(rename INNER" "(rename HORIZON" "(rename VERTICAL" "(rename BORDER" "(rename DESIGN" "(rename ECOLOGY" "(rename APPROVED" "(rename MANUFACTURER"}
	set filterEDF {}
	set fileHandle [open $edfFilePath r]
	while {[gets $fileHandle line] >= 0} {
		# Read EDF line-by-line.
		set removeLeftSpace [string trimleft $line]
		set matchKeep [startsWithAnyPrefix $removeLeftSpace $startWordsKeep]
		set matchThrow [startsWithAnyPrefix $removeLeftSpace $startWordsThrow]
		if {$matchKeep eq 1 && $matchThrow eq 0} {
			lappend filterEDF [string trim $line]
		}
	}
	close $fileHandle
	
	return $filterEDF
}

proc startsWithAnyPrefix {str prefixes} {
	# Check whether the str starts with the prefixes or not.
    foreach prefix $prefixes {
        if {[string first $prefix $str] == 0} {
            return 1
        }
    }
    return 0
}

proc GetSchematicFolderName {filterEDFList} {
	# Get schematic folder name inside the OrCAD file hierarchy.
	set length [llength $filterEDFList]
	
	for {set i 0} {$i < $length} {incr i} {
		set rowData [lindex $filterEDFList $i]
		if {[string first "(rename SCHEMATIC1" $rowData] == 0} {
			set splitRowData [split [string trim $rowData] " "]
			# Remove " & ) for the folder name.
			set folderName [string map {"\"" "" ")" ""} [lindex $splitRowData 2]]
			return $folderName
		}
	}
	return "SCHEMATIC1"
}

proc GetSchematicPage {filterEDFList partRef} {
	# Get the page text for the target part reference.
	set length [llength $filterEDFList]
	
	# Get the part reference string index.
	set partRefIndex -1
	for {set i 0} {$i < $length} {incr i} {
		if {[lindex $filterEDFList $i] eq "(stringDisplay \"$partRef\""} {
			set formerRow [lindex $filterEDFList [expr $i - 1]]
			if {[string first "(cellRef " $formerRow] == 0} {
				set partRefIndex $i
				break
			}
		}
	}
	
	# Search backward from the part reference index to find the page name.
	if {$partRefIndex ne -1} {
		for {set pridx $partRefIndex} {$pridx >= 0} {incr pridx -1} {
			if {[lindex $filterEDFList $pridx] eq "(page"} {
				# The next line for the "(page" seems to be the page name.
				set nextLine [lindex $filterEDFList [expr {$pridx + 1}]]
				# Use reX to extract the string in the "".
				if {[regexp {"(.*?)"} $nextLine match group]} {
					return $group
				}
			}
		}
		return ""
	} else {
		error "Can't find ${partRef} in the EDF file."
	}
}

proc GetSymbolCoordinates {filterEDFList partRef} {
	# Get coordinates under "(transform".
	set length [llength $filterEDFList]
	
	# Get the part reference string index.
	set partRefIndex -1
	for {set i 0} {$i < $length} {incr i} {
		if {[lindex $filterEDFList $i] eq "(stringDisplay \"$partRef\""} {
			set formerRow [lindex $filterEDFList [expr $i - 1]]
			if {[string first "(cellRef " $formerRow] == 0} {
				set partRefIndex $i
				break
			}
		}
	}
	
	# Search down to get the coordinates.
	for {set pridx $partRefIndex} {$pridx < $length} {incr pridx} {
		set rowData [lindex $filterEDFList $pridx]
		if {$rowData eq "(transform"} {
			# Get symbol coordinates.
			set nextLine [lindex $filterEDFList [expr $pridx + 1]]
			if {[string first "(ori" $nextLine] == 0} {
				# Processing rotating symbol.
				set coorLine [lindex $filterEDFList [expr $pridx + 2]]
				set splitCoor [split [string trim $coorLine] " "]
				set coorX [format {%0.2f} [expr [string map {"-" ""} [lindex $splitCoor 1]] / 100.00]]
				set coorY [format {%0.2f} [expr [string map {"-" "" ")" ""} [lindex $splitCoor 2]] / 100.00]]
				set coorY [format {%0.2f} [expr $coorY - 0.05]]
				set coor [list $coorX $coorY]
				
				return $coor
			} else {
				# Processing normal symbol.
				set splitCoor [split [string trim $nextLine] " "]
				set coorX [format {%0.2f} [expr [string map {"-" ""} [lindex $splitCoor 1]] / 100.00]]
				set coorY [format {%0.2f} [expr [string map {"-" "" ")" ""} [lindex $splitCoor 2]] / 100.00]]
				set coorX [format {%0.2f} [expr $coorX + 0.05]]
				set coor [list $coorX $coorY]
				
				return $coor
			}
		}
	}
}

proc DisplayRC {} {
	# Making R_C_Property Visible.
	set lStatus [DboState]
	set lCStr [DboTclHelper_sMakeCString]
	# Set target property as "R_C_Property".
	set lPropName [DboTclHelper_sMakeCString "R_C_Property"]
	set pLocation [DboTclHelper_sMakeCPoint 0 0]
	# Set font attributes like size, quality ...etc.
	set pFont [DboTclHelper_sMakeLOGFONT "Arial" 12 0 0 0 400 0 0 0 0 7 0 1 16]
	set lPage [GetActivePage]
	set lSelectedObjectsList [GetSelectedObjects] 
	foreach lObj $lSelectedObjectsList {
		$lObj GetTypeString $lCStr
		set lObjTypeStr [DboTclHelper_sGetConstCharPtr $lCStr]
		if { $lObjTypeStr == "Placed Instance" } {
			set lProp [$lObj NewDisplayProp $lStatus $lPropName $pLocation 0 $pFont 48]
			DboPartInst_PositionDisplayProp $lPage $lProp
		}
	}
	UnSelectAll
	catch {Menu View::Zoom::Redraw}
}
