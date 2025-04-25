# Display Properties .
# tclsh ~/main.tcl DSNFile
# 1. Open DSN file
# 2. Get all part reference that need to display Property.
# 3. Loop [Select all symbols in a page and display.]

set localWorkDir "workDir"
set capAutoLoad "C:/Cadence/SPB_23.1/tools/capture/tclscripts/capAutoLoad/"
source "~/GlobalProc.tcl"
namespace import GlobalProc::ReplaceTXTKeyword

proc main {inputDSNFilePath} {
	set inputDSNFilePath [string map {\\ /} $inputDSNFilePath]
	InitSetup $inputDSNFilePath
	exec cmd /c "cd /d C:/Cadence/SPB_23.1/tools/bin && capture ~/CMD.tcl"
	DeleteFiles
	puts "All processes done. You can find updated DSN at your input path."
	exit
}

proc InitSetup {inputDSNFilePath} {
	# Create work directory, process xml files.
	puts "Setting Environment..."
	global localWorkDir
	
	CreateFolder $localWorkDir
	CopyFiles2Local
	
	set dsnName [file tail $inputDSNFilePath]
	set dsnPureName [file rootname $dsnName]
	set dsnDirName [file dirname $inputDSNFilePath]
	
	CreateFolder "${dsnDirName}/${dsnPureName}_display"
	
	ReplaceTXTKeyword "${localWorkDir}Bill_of_Materials.xml" "input_file_pure_name" $dsnPureName
	ReplaceTXTKeyword "${localWorkDir}Select_Project_Type.xml" "input_file_pure_name" $dsnPureName
	after 1000
	ReplaceTXTKeyword "${localWorkDir}Select_Project_Type.xml" "input_file_dir_path" $dsnDirName
	ReplaceTXTKeyword "${localWorkDir}CMD.tcl" "input_DSN_file_path" $inputDSNFilePath
}

proc CreateFolder {folderPath} {
	# Create a folder path.
	set isdir [file isdirectory $folderPath]
	if {$isdir eq 0} {
		file mkdir $folderPath
	}
}

proc CopyFiles2Local {} {
	global localWorkDir
	global capAutoLoad
	
	# Copy xml files from file server to workDir.
	set fileSvrPath "//serverPath"
	file copy -force "${fileSvrPath}XML/Select_Project_Type.xml" $localWorkDir
	file copy -force "${fileSvrPath}XML/Bill_of_Materials.xml" $localWorkDir
	
	# Copy tcl code to capAutoLoad
	file copy -force "${fileSvrPath}TclCode/GlobalProc.tcl" $capAutoLoad
	file copy -force "${fileSvrPath}TclCode/ReadFiles.tcl" $capAutoLoad
	file copy -force "${fileSvrPath}TclCode/DisplayProperties.tcl" $capAutoLoad
	
	file copy -force "${fileSvrPath}TclCode/CMD.tcl" $localWorkDir
}

proc DeleteFiles {} {
	# Delete all related files.
	global localWorkDir
	global capAutoLoad
	
	file delete -force "${capAutoLoad}GlobalProc.tcl"
	file delete -force "${capAutoLoad}DisplayProperties.tcl"
	file delete -force "${capAutoLoad}ReadFiles.tcl"
	# Remove entire folder.
	foreach $localWorkDir [glob *] {
		file delete -force -- $localWorkDir
	}
}

if {$argc == 0} {
	puts "Usage: mytcl.exe param"
    exit
} else {
	set inputFilePath [lindex $argv 0]
	set fileExtension [file extension $inputFilePath]
	if {$fileExtension eq ".DSN"} {
		puts "=====Start displaying Property====="
		main $inputFilePath
	} else {
		puts "Please input DSN file."
		exit
	}
}
