proc GetDateTime {} {
	# Get date & time as file name.
	set currentTimeSeconds [clock seconds]
	set currentDateTime [clock format $currentTimeSeconds -format "%Y%m%d-%H%M%S"]
	
	return $currentDateTime
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
