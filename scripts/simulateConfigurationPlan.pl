#
# Author: Marco Sirianni
#
#

use XML::XPath;
use Array::Utils qw(:all);


if ( @ARGV < 1  ) 
 {
  die  "
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

"
}

print "\n";


#########################
#  Variable declaration #
#########################

# E' un array (un elemento per ogni definizione **wsdlAndSchema**) che contiene un array stringhe 
# (ovvero i nomi dei wsdl a cui applicare la customizzazione)
my @list_of_wsdlInCustomization;

# E' un array (un elemento per ogni definizione **wsdlAndSchema**) che contiene un hashmap
# (ovvero un hashmap che contiene la coppia token => puntamento da sostituire)
my @list_of_token = ({},);

#E' un array che contiene tutti i nomi dei wsdl puntati come reference nel composite
my @composite_refs;

#E' un array che contiene tutti i nomi dei wsdl nella directory corrente
#TODO specificare una o piu' cartelle da cui prelevare i WSDL
my @directory_wsdl;

my $wsdlAndSchemaIndex = 0;


############################
# READ CUSTOMIZZATION FILE #
############################

#Error output log
$output_error_log = '';


#Il nome del file di customizzazione
$customizationFileName = "@ARGV[0]";

#Apro il file di customizzazione
$customizationFile = XML::XPath->new(filename => $customizationFileName) or die "Error, the file specified cannot be found";

#Con una query XPATH recupero le customizzazioni
$nodeset = $customizationFile->find('//wsdlAndSchema') or die "There are no customization to apply"; 

#Recupero i dati delle sostituzioni che il file di customizzazione applica
@values = $nodeset->get_nodelist;

#Per ogni tag wsdlAndSchema 
foreach $val (@values)
{
	my $wsdlAttribute = $val->getAttribute('name');
	
	#Lista di wsdl a cui applicare la customizzazione
	@wsdlInCustomization = split('\|',$wsdlAttribute); 
	
	push (@{$list_of_wsdlInCustomization[$wsdlAndSchemaIndex]},@wsdlInCustomization);
	
	my $searchReplace_tmp = $customizationFile->find('./searchReplace', $val);
	 
	@searchReplace = $searchReplace_tmp->get_nodelist;
	 
	foreach $val2 (@searchReplace)
	{	
		my $search_tmp = $customizationFile->find('./search', $val2);
		
		@search = $search_tmp->get_nodelist;
		
		#print $search[0]->string_value." - ";
		
		my $replace_tmp = $customizationFile->find('./replace', $val2);
		
		@eplace = $replace_tmp->get_nodelist;
		
		#print $eplace[0]->string_value;
		
		#print "\n";
		
		$list_of_token[$wsdlAndSchemaIndex]{$search[0]->string_value} = $eplace[0]->string_value;
	}
	
	$wsdlAndSchemaIndex++;
}

##################################
# READ REFERENCES FROM COMPOSITE #
##################################

my $compositeFile = XML::XPath->new(filename => "composite.xml") or die "Error, cannnot find the composite file";

#Con una query XPATH recupero le customizzazioni
my $nodeset_refs = $compositeFile->find('//reference') or die "There are no customization to apply"; 

#Recupero i dati delle sostituzioni che il file di customizzazione applica
@values_ref = $nodeset_refs->get_nodelist;

foreach $value_ref (@values_ref)
{
	#print $value_ref->getAttribute('ui:wsdlLocation')."\n";
	
	push(@composite_refs, $value_ref->getAttribute('ui:wsdlLocation'));
}

print "The composite contains the following references: \n\n";

foreach $tmp (@composite_refs)
{
	print " -- ".$tmp." \n";
}


#####################################
# READ FILES FROM CURRENT DIRECTORY #
#####################################

print "\n\nLoading wsdl in current directory...  ";

opendir CurrentDir, ".";     # . is the current directory
while ( $filename = readdir(CurrentDir) ) {

	if($filename  =~ '.*\.wsdl')
	{
		#print $filename , "\n";
		push (@directory_wsdl,$filename);
	}
}

closedir CurrentDir;



#+++++++++++++++++++++++++++++#
# INIZIO CHECK DI CORRETTEZZA #
#+++++++++++++++++++++++++++++#

###########################################
# CHECK WSDL DUPLICATE IN WSDL_AND_SCHEMA #
###########################################

#
## TODO
#

#######################################
# CHECK WSDL PRESENTI NELLA DIRECTORY #
#######################################

print "\n\nChecking if all reference exist in current directory ... ";

my @minus = array_minus( @composite_refs, @directory_wsdl );

if (scalar @minus != 0)
{
	foreach $tmp (@minus)
	{
		$output_error_log .= $tmp." does not exist in the current directory!!\n";
	}
	
	$output_error_log eq '' or  (print $output_error_log."\n" and die "!PLEASE FIX THE PROJECT AND ADD THE MISSING FILES BEFORE PROCEEDING!\n");
	
}

if($output_error_log eq '')
{
	print "ok\n";
}
else
{
	print "fail\n";
}

#############################################################
# CHECK COMPOSITE REFERENCE PRESENTI NEL CUSTOMIZATION FILE #
#############################################################

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
		$output_error_log .="Error, the reference ".$temp_ref." exists in the composite file but is not mapped for token substitution in ".$customizationFileName."\n\n";
	}
	
}
if($output_error_log eq '')
{
	print "ok\n";
}
else
{
	print "fail\n";
}

######################
# CHECK CONDIZIONI 1 #
######################

print "Checking wsdl for errors ... ";

foreach my $temp_wsdl (@composite_refs)
{
	my $wsdl_File = XML::XPath->new(filename => $temp_wsdl) or die "Error, the file ".$temp_wsdl." cannot be found";

	#Con una query XPATH recupero il service
	my $nodeset_service = $wsdl_File->find("//*[local-name() ='service']//*[local-name() = 'address']") or $output_error_log .= "Node service does not exists (abstract wsdl) for".$wsdl_File.".. skipping file...\n"; 

	#Recupero i dati delle sostituzioni che il file di customizzazione applica
	@values_service = $nodeset_service->get_nodelist;
	
	#Ce ne sarà soltanto uno ma per correttezza cicliamo sui risultati
	foreach my $wsdl_service_location (@values_service)
	{
		#print $wsdl_service_location->getAttribute('location')."\n\n\n";
		my $wsdl_service_location_url = $wsdl_service_location->getAttribute('location');
		
		#print $wsdl_service_location_url."\n";

		#Ciclo sui wsdlAndSchema trovati nel customizzation file
		my $index = 0;
		foreach $val4 (@list_of_token)
		{
			# Devo considerare il wsdl corrente solo se si trova nella definizione di wsdlAndSchema corrispondente ad index
			
			#print $temp_wsdl." - ".$index." - ".($temp_wsdl ~~  @list_of_wsdlInCustomization[$index] )."\n";
			
			if ($temp_wsdl ~~  @list_of_wsdlInCustomization[$index])
			{			
				#print " trovato --> ".$index."\n";
				
				$token_presente = 0;
				#Ciclo sulle coppie token puntamenti			
				while( my ($k, $v) = each %$val4 ) 
				{
					#print $k." ";
					#print index($wsdl_service_location_url, $k).", ";
					
					# Controllo se l'url è presente nella location
					# Non ci devono essere puntamenti!!
					if (index($wsdl_service_location_url, $v) == 0)
					{
						$output_error_log .="Error, endpoint ".$wsdl_service_location_url." found in file ".$temp_wsdl."\n\n";
					}
					
					# Controllo se è presente il token corrente
					# Ci deve essere almeno uno dei token
					if (index($wsdl_service_location_url, $k) == 0)
					{
						$token_presente = 1;
					}

				}
				
				if($token_presente == 0)
				{
					$output_error_log .=" Error, non of the specified token substitution has been found in file ".$temp_wsdl."\n\n";
				}
				#print "\n";
			}
			$index += 1;
		}

	}
	
}

if($output_error_log eq '')
{
	print "ok\n";
}
else
{
	print "fail\n";
}
 

if($output_error_log eq '')
{
	print "\n\nConfiguration is correct!!\n";
}

else
{
	# Stampa lo stack dei messaggi di errore
	print "\n\n".$output_error_log;
}
