SOAUtils
========

This repository contains script and resources for simplifying the developing process with Oracle SOA and BPM products


Up to now I am working on a script that check that the configuration plan attached to a composite application deployment package 
is not faulty, and that the current project configutation is in general correct.

It follows the help screenshot of the script, it's in italian I will translate it soon...

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


