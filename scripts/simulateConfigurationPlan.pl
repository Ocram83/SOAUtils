#
# Author: Marco Sirianni
#
# A seguito di eventuali modifiche o correzioni, aggiungere un commento qui sotto
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
  
  Questo script riceve in input il percorso relativo del file di customizzazione da applicare
  
  Questo script deve essere eseguito dalla cartella in cui si trova l'applicazione soa (stessa cartella del file composite.xml)
  
  Dato il file di customizzazione in input lo script verifica le seguenti condizioni
		
		1) nei file wsdl a cui si chiede di applicare la trasformazione siano stati sostituiti effettivamente i placeholder indicati 
		  (controlla unicamente il puntamento nel service). Il controllo consiste nel verificare se :
			1.2) prima della sostituzione sia presente uno di puntamenti (quindi se MANCA IN PALCEHOLDER)
			1.2) dopo aver eseguito la sostituzione, nel verificare se dopo l'indirizzo del service contenga la stringa si sostituzione
				(quindi se qualche PLACEHOLDER E' SCRITTO ERRONEAMENTE)
		
		2) Le reference del composite siano tutte presenti nella cartella e nell'elenco di file a cui applicare le custommizazioni.
			2.1) Si suppone che tutti i wsdl siano nella root del progetto.
		
  Lo script e' in grado quindi di verificare se 
	a) manca qualche placeholder
	b) qualche placeholder e' scritto erroneamente
	c) se manca qualche file wsdl ( improbabile)
	d) se qualche file non e' incluso nella ricerca delle sostituzioni del file di customizzazione

   
   Questa versione dello script non verifica ancora se il customizzation file contiene puntamenti a file inesistenti.

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
$customizationFile = XML::XPath->new(filename => $customizationFileName) or die "Impossibile trovare il file specificato";

#Con una query XPATH recupero le customizzazioni
$nodeset = $customizationFile->find('//wsdlAndSchema') or die "Non ci sono castomizzazioni da applicare"; 

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

#
# DECOMMENTARE PER VERIFICARE IL CONTENUTO DI  list_of_wsdlInCustomization E DI list_of_token
#
#foreach $val4 (@list_of_wsdlInCustomization)
#{
#	print " --> ";
#	foreach $val5 (@{$val4})
#	{
#		print $val5." - ";
#	}
#	print "\n";
#}

# foreach $val4 (@list_of_token)
# {
	# print " --> ";
	
	# while( my ($k, $v) = each %$val4 ) {
        # print "key: $k, value: $v.\n";
    # }
	# print "\n";
# }


##################################
# READ REFERENCES FROM COMPOSITE #
##################################

my $compositeFile = XML::XPath->new(filename => "composite.xml") or die "Impossibile trovare il composite file";

#Con una query XPATH recupero le customizzazioni
my $nodeset_refs = $compositeFile->find('//reference') or die "Non ci sono castomizzazioni da applicare"; 

#Recupero i dati delle sostituzioni che il file di customizzazione applica
@values_ref = $nodeset_refs->get_nodelist;

foreach $value_ref (@values_ref)
{
	#print $value_ref->getAttribute('ui:wsdlLocation')."\n";
	
	push(@composite_refs, $value_ref->getAttribute('ui:wsdlLocation'));
}

# foreach $tmp (@composite_refs)
# {
	# print $tmp." - ";
# }


#####################################
# READ FILES FROM CURRENT DIRECTORY #
#####################################

opendir CurrentDir, ".";     # . is the current directory
while ( $filename = readdir(CurrentDir) ) {

	if($filename  =~ '.*\.wsdl')
	{
		#print $filename , "\n";
		push (@directory_wsdl,$filename);
	}
}

closedir CurrentDir;

# foreach $tmp (@directory_wsdl)
# {
	# print $tmp." - ";
# } 



#+++++++++++++++++++++++++++++#
# INIZIO CHECK DI CORRETTEZZA #
#+++++++++++++++++++++++++++++#


#######################################
# CHECK WSDL PRESENTI NELLA DIRECTORY #
#######################################

my @minus = array_minus( @composite_refs, @directory_wsdl );

if (scalar @minus == 0)
{
	print  "Tutti i wsdl sono presenti nella cartella.\nProcedo con la verifica... \n\n";
}
else
{
	foreach $tmp (@minus)
	{
		$output_error_log .= $tmp." non e' presente nella cartella!!\n";
	}
	
	$output_error_log eq '' or  (print $output_error_log."\n" and die "!RIPRISTINARE I FILE MANCANTI PRIMA DI PROCEDERE!\n");
	
}

#############################################################
# CHECK COMPOSITE REFERENCE PRESENTI NEL CUSTOMIZATION FILE #
#############################################################

foreach my $temp_ref (@composite_refs)
{
	foreach my $tmp_wsdlAndSchema (@list_of_wsdlInCustomization)
	{
		my @minus_wsdlAndSchema = array_minus( @composite_refs, @$tmp_wsdlAndSchema );
		
		foreach my $tmp1 (@$tmp_wsdlAndSchema)
		{
		#	print $tmp1." ";
		}
		#print "\n\n\n";
		if (scalar @minus == 0)
		{
			#print  "Tutti i reference sono presenti nella file di customizzazione\n\n";
		}
		else
		{
		#	print "Non presente\n";
		}
	}
}


######################
# CHECK CONDIZIONI 1 #
######################

foreach my $temp_wsdl (@composite_refs)
{
	my $wsdl_File = XML::XPath->new(filename => $temp_wsdl) or die "Impossibile trovare il file specificato";

	#Con una query XPATH recupero il service
	my $nodeset_service = $wsdl_File->find("//*[local-name() ='service']//*[local-name() = 'address']") or print "Nodo service non presente.. skipping file...\n"; 

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
						$output_error_log .="Errore, trovato il puntamento ".$wsdl_service_location_url." nel file ".$temp_wsdl."\n\n";
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
					$output_error_log .=" Errore, nessuno dei token indicati come sostituzione trovati nel file ".$temp_wsdl."\n\n";
				}
				#print "\n";
			}
			$index += 1;
		}

	}
	
}

if($output_error_log eq '')
{
	print "Configurazione corretta!\n";
}

else
{
	# Stampa lo stack dei messaggi di errore
	print $output_error_log;
}