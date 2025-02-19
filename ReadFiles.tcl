oo::class create ReadFiles
oo::define ReadFiles {
	# Initial.
	variable inputFile inputFileType
	constructor {filePath fileType} {
		set inputFile $filePath
		set inputFileType $fileType
	}
	destructor {
		puts "Instance destroyed."
	}
	
	# Use "sep" parameter to identify txt or csv file.
	method readFile {sep} {
		set fexist [expr {![catch {file lstat $inputFile finfo}]}]
		if {$fexist == 1} {
			if {[file extension $inputFile] eq ".$inputFileType"} {
				# Read a .csv file.
				set fileName $inputFile
				set fileId [open $fileName r]
				set dataList {}
				while {[gets $fileId line] != -1} {
					if {$sep != ""} {
						set row [split $line $sep]
						lappend dataList $row
					} else {
						lappend dataList $line
					}
				}
				close $fileId
				# remove first row
				#set dataList [lreplace $dataList 0 0]
				
				return $dataList
			} else {
				error "$inputFile needs to be a .$inputFileType file."
			}
		} else {
			error "$inputFile does not exist."
		}
	}
}

proc GetFilesInFolder {dirPath extension} {
	# Use glob to get a list of all files with the specified extension in the directory
	set fileList [glob -directory $dirPath *.$extension]
	
	return $fileList
}
