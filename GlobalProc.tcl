namespace eval GlobalProc {
	namespace export ReplaceTXTKeyword
 	namespace export ReplaceTextPairs

  	proc GetDateTime {} {
		# Get date & time as file name.
		set currentTimeSeconds [clock seconds]
		set currentDateTime [clock format $currentTimeSeconds -format "%Y%m%d-%H%M%S"]
	
		return $currentDateTime
	}
   
   	proc ReplaceTXTKeyword {TXTFilePath oldText newText} {
		# Check if the file exists.
    		if {![file exists $TXTFilePath]} {
        		puts "Error: File $TXTFilePath does not exist."
        		return
    		}

		# Read the file content.
		set readFileHandle [open $TXTFilePath r]
		set fileContent [read $readFileHandle]
		close $readFileHandle
		
		# Replace the old text with the new text.
		set updatedContent [string map [list $oldText $newText] $fileContent]
		
		# Write the updated content back to the file.
		set writeFileHandle [open $TXTFilePath w]
		puts -nonewline $writeFileHandle $updatedContent
		close $writeFileHandle
	}

 	proc ReplaceTextPairs {textFilePath textPairs} {
		# Check if the file exists.
		if {![file exists $textFilePath]} {
			puts "Error: File $textFilePath does not exist."
			return
		}
	
		# Read the file content.
		set readFileHandle [open $textFilePath r]
		set fileContent [read $readFileHandle]
		close $readFileHandle
	
		# Create a list to hold the mapping pairs
		set mappingList {}
		foreach {oldText newText} $textPairs {
			lappend mappingList $oldText $newText
		}
	
		# Replace the old texts with the new texts.
		set updatedContent [string map $mappingList $fileContent]
	
		# Write the updated content back to the file.
		set writeFileHandle [open $textFilePath w]
		puts -nonewline $writeFileHandle $updatedContent
		close $writeFileHandle
	}
}

proc CheckArgsType {x2 y2} {
	# Check arguments type.
	if {![string is double -strict $x2]} {
        error "Error: Symbol size must be a number."
    }
	if {![string is double -strict $y2]} {
        error "Error: Symbol size must be a number."
    }
}

proc RenameExtension {filePath ext} {
	# Rename the extension of a file path.
	set fileRoot [file rootname $filePath]
	set newFilePath "${fileRoot}.$ext"
	
	return $newFilePath
}

proc convertSlashes {path} {
	return [string map {/ \\} $path]
}

proc GetUser {} {
	# It will get compal\username.
	set usr [exec whoami]
	return $usr
}

proc GetUserPath {folderName} {
	if {[info exists env(USERPROFILE)]} {
		set folderPath "$env(USERPROFILE)/$folderName"
		
		return $folderPath
	}
}
