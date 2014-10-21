SOAUtils
========

This repository contains script and resources for simplifying the developing process with Oracle SOA and BPM products


Up to now I am working on a script that check that the configuration plan attached to a composite application deployment package 
is not faulty, and that the current project configutation is in general correct.

It follows the help screenshot of the script, it's in italian I will translate it soon...

########
# HELP #
########

This script take as input the relative path to a customization file.

This script must be run from the SOA application directory (the same as the one of the composite.xml)

Given the customization file, the composite file, and the wsdl associated to the customization the script verify the following condition
	
	1) All wsdl referred in the composite exist in the current directory..
	2) All wsdl referred in the composite have a corrispendent token substitution in customization file.
	3) Placeholder as been substituted to machine endopoint in all wsdl (there are no machine endpoint in wsdl).
	4) One of the placeholder must be found in the service node of the wsdl.
	
	
The script allows for find out if

	a) some placeholder is missing
	b) some placeholder is mispelled
	c) some wsdl file is missing
	d) some wsdl file is not included in customization file

Remenber that it's up to you to check that the correct token is substituted in the service node of wsdl.
This script allows for checking syntactic correctness.
