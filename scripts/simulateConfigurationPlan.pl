#
# Author: Marco Sirianni
#
# External modules: 
#
# http://search.cpan.org/~msergeant/XML-XPath-1.13/XPath.pm
# http://search.cpan.org/dist/Array-Utils/Utils.pm
#
#
package soaUtils;

use XML::XPath;
use Array::Utils qw(:all);

use strict;
use warnings;

if ( @ARGV < 1  ) 
 {
  die  "
  ########
  # HELP #
  ########
  
  This script take as input the relative path to a customization file.
  
  This script must be run from the SOA application directory (the same as the one of the composite.xml)
  
  Given the customization file, the composite file, and the wsdls associated to the customization the script verify the following condition
		
	1) All wsdl referred in the composite exist in the current directory..
	2) All wsdl referred in the composite have a corrispendent token substitution in customization file.
	3) Placeholder as been substituted to machine endopoint in all wsdl (there are no machine endpoint in wsdl).
	4) One of the placeholder must be found in the service node of the wsdl (placeholder is not mispelled).
		
		
  The script allows for find out if
  
	a) some placeholder is missing
	b) some placeholder is mispelled
	c) some wsdl file is missing
	d) some wsdl file is not included in customization file

	Remenber that it's up to you to check that the correct token is substituted in the service node of wsdl.
	This script allows for checking syntactic correctness.

"
}

print "\n";


#########################
#  Variable declaration #
#########################

# It's an array (one element for each definition of **wsdlAndSchema**) which contains an array of string 
# (that is, the name of the wsdls which we want to customize)
my @list_of_wsdlInCustomization;

# It's an array (one element for each definition of **wsdlAndSchema**) which contains an hashmap
# (that is,  an hashmap  which contains the pair token => machine endopoint)
my @list_of_token = ({},);

# It's an array which containts the name of the wsdls which appear as a reference in the composite application
my @composite_refs;

# It's an array which containts the name of the wsdls
### TODO we may want to specify the directory which contains the wsdls or maybe get the relative path from the composite application.
my @directory_wsdl;

my $wsdlAndSchemaIndex = 0;


############################
# READ CUSTOMIZZATION FILE #
############################

#Error output log
my $output_error_log = '';


#The name of the customizzation file
my $customizationFileName = "$ARGV[0]";

#Open the customization file
my $customizationFile = XML::XPath->new(filename => $customizationFileName) or die "Error, the file specified cannot be found";

#XPATH expression to retrieve the customizations 
my $nodeset = $customizationFile->find('//wsdlAndSchema') or die "There are no customization to apply"; 

#Get the nodeset
my @values = $nodeset->get_nodelist;

#For each tag wsdlAndSchema 
foreach my $val (@values)
{
	my $wsdlAttribute = $val->getAttribute('name');
	
	#List of wsdls to customize
	my @wsdlInCustomization = split('\|',$wsdlAttribute); 
	
	push (@{$list_of_wsdlInCustomization[$wsdlAndSchemaIndex]},@wsdlInCustomization);
	
	my $searchReplace_tmp = $customizationFile->find('./searchReplace', $val);
	 
	my @searchReplace = $searchReplace_tmp->get_nodelist;
	 
	foreach my $val2 (@searchReplace)
	{	
		my $search_tmp = $customizationFile->find('./search', $val2);
		
		my @search = $search_tmp->get_nodelist;
				
		my $replace_tmp = $customizationFile->find('./replace', $val2);
		
		my @eplace = $replace_tmp->get_nodelist;
		
		$list_of_token[$wsdlAndSchemaIndex]{$search[0]->string_value} = $eplace[0]->string_value;
	}
	
	$wsdlAndSchemaIndex++;
}

##################################
# READ REFERENCES FROM COMPOSITE #
##################################

my $compositeFile = XML::XPath->new(filename => "composite.xml") or die "Error, cannnot find the composite file";

#XPATH expression to retrieve the references in composite file 
my $nodeset_refs = $compositeFile->find('//reference') or die "There are no customization to apply"; 

#Get the nodeset
my @values_ref = $nodeset_refs->get_nodelist;

foreach my $value_ref (@values_ref)
{	
	push(@composite_refs, $value_ref->getAttribute('ui:wsdlLocation'));
}

print "The composite contains the following references: \n\n";

foreach my $tmp (@composite_refs)
{
	print " -- ".$tmp." \n";
}


#####################################
# READ FILES FROM CURRENT DIRECTORY #
#####################################

print "\n\nLoading wsdl in current directory...  ";

opendir CurrentDir, ".";     # . is the current directory
while (my $filename = readdir(CurrentDir) ) {

	if($filename  =~ '.*\.wsdl')
	{
		#print $filename , "\n";
		push (@directory_wsdl,$filename);
	}
}

closedir CurrentDir;

#++++++++++++++++++++++++++#
# START CORRECTNESS CHECKS #
#++++++++++++++++++++++++++#

############################
# CHECK WSDLs NOT EXISTING #
############################

print "\n\nChecking if all reference exist in current directory ... ";

my @minus = array_minus( @composite_refs, @directory_wsdl );
my $output_error_log_local = '';

if (scalar @minus != 0)
{
	foreach my $tmp (@minus)
	{
		$output_error_log_local .= $tmp." does not exist in the current directory!!\n";
		$output_error_log .= $output_error_log_local;
	}
	
}

if($output_error_log_local eq '')
{
	print "ok\n";
}
else
{
	print "fail\n";
	print $output_error_log_local."\n" and die "!PLEASE FIX THE PROJECT AND ADD THE MISSING FILES BEFORE PROCEEDING!\n";
}

#Reset local error variable
$output_error_log_local = '';

############################################################
# CHECK COMPOSITE REFERENCE PRESENTI IN CUSTOMIZATION FILE #
############################################################

print "Checking if all composite reference exist in customization file ... ";

foreach my $temp_ref (@composite_refs)
{
	my $ref_found = 0;
	foreach my $tmp_wsdlAndSchema (@list_of_wsdlInCustomization)
	{
		
		if ($temp_ref ~~ @$tmp_wsdlAndSchema)
		{
			$ref_found = 1;
		}
	}
	
	if($ref_found != 1)
	{
		$output_error_log_local .="Error, the reference ".$temp_ref." exists in the composite file but is not mapped for token substitution in ".$customizationFileName."\n\n";
		$output_error_log .= $output_error_log_local;
	}
	
}

if($output_error_log_local eq '')
{
	print "ok\n";
}
else
{
	print "fail\n";
}

#Reset local error variable
$output_error_log_local = '';

#####################
# CHECK CONDIZIONIs #
#####################

print "Checking wsdl for errors ... ";

foreach my $temp_wsdl (@composite_refs)
{
	my $wsdl_File = XML::XPath->new(filename => $temp_wsdl) or die "Error, the file ".$temp_wsdl." cannot be found";

	#XPATH expression to retrieve the references in composite file 
	my $nodeset_service = $wsdl_File->find("//*[local-name() ='service']//*[local-name() = 'address']") or $output_error_log .= "Node service does not exists (abstract wsdl) for".$wsdl_File.".. skipping file...\n"; 

	#Get nodeset
	my @values_service = $nodeset_service->get_nodelist;
	
	#There will always be only one, anyway we iterate
	foreach my $wsdl_service_location (@values_service)
	{
		#print $wsdl_service_location->getAttribute('location')."\n\n\n";
		my $wsdl_service_location_url = $wsdl_service_location->getAttribute('location');
		
		#Cycle on wsdlAndSchema found in customization file
		my $index = 0;
		foreach my $val4 (@list_of_token)
		{
			# Current wsdl will be considered only if found in the definition of wsdlAndSchema corresponding to index
			
			if ($temp_wsdl ~~  $list_of_wsdlInCustomization[$index])
			{							
				my $token_found = 0;
				#Cycle on pairs of token -> machine endpoint
				while( my ($k, $v) = each %$val4 ) 
				{
					
					# Check if an url is found inside location
					# There must not be any machine endpoint!!
					if (index($wsdl_service_location_url, $v) == 0)
					{
						$output_error_log_local .="Error, endpoint ".$wsdl_service_location_url." found in file ".$temp_wsdl."\n\n";
						$output_error_log .= $output_error_log_local;
					}
					
					# Check if current token apperas in the location
					# There must be exactly one token!!
					if (index($wsdl_service_location_url, $k) == 0)
					{
						$token_found += 1;
					}

				}
				
				if($token_found != 1)
				{
					$output_error_log_local .=" Error, non of the specified token substitution has been found in file ".$temp_wsdl."\n\n";
					$output_error_log .= $output_error_log_local;
				}
				#print "\n";
			}
			$index += 1;
		}

	}
	
}

###########
## TODOs ##
###########

# CHECK WSDL DUPLICATE IN WSDL_AND_SCHEMA

# CHECK WSDL NOT USED AS REFERENCE

#################
# PRINT RESULTS #
#################

if($output_error_log_local eq '')
{
	print "ok\n";
}
else
{
	print "fail\n";
}
 
$output_error_log_local = '';

if($output_error_log eq '')
{
	print "\n\nConfiguration is correct!!\n";
}

else
{
	# Print error stack
	print "\n\n".$output_error_log;
}
