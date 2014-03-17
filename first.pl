#!/usr/bin/perl
use CGI;
use LWP::Simple;
use Text::English; #PStemmer 
my $inputDir = "inputfile";
my %invertedTable = ();
my $q = CGI->new;
my $val = $q->param('sendData0');

print $q->header;

my $query = $val;

print "Your Search Result for:: $query";

my @stopWordList = ();
my $url = "http://www.cs.memphis.edu/~vrus/teaching/ir-websearch/papers/english.stopwords.txt";
my $stopWord = get($url) or die("Unable to Open");
@stopWordList = split(/\s+/,$stopWord);

#subroutine to remove stop words
sub removeStopWord{
	my $input = $_[0];
	#print $input;
	foreach $word (@stopWordList)
	{
	#print "'".$word."'\n";
	$input =~ s/\b$word\b//g;
	}
	#print $input;
	return $input;
}

sub performStemming{
my $input = $_[0];
my @inputList = split(/\s+/,$input);
my @stemwords = Text::English::stem(@inputList);
my $outString = "";
foreach $ww (@stemwords)
	{
	$outString = $outString." ".$ww;
	}
#print $outString;
return $outString;
}

sub queryPreprocessing{
my $inputQuery = $_[0];
#print $inputQuery."\n";
$inputQuery =~ s/\s+/ /g;
$inputQuery =~ s/<!--(.|\s)*?-->//g;
$inputQuery =~ s/<[^>]*>//g;
$inputQuery =~ s/[0-9]+/ /g;
$inputQuery =~ s/[,\[\]\"!=\$'_\.\-\|:;~\*\\@\/%\#\&\?\(\)]+/ /g;
$inputQuery =~ s/[\^\+]+/ /g;
$inputQuery =~ s/[\{,\}]+/ /g;
$inputQuery =~ s/[\“\’\–\”\—\…]+//g;
$inputQuery =~ tr/A-Z/a-z/;
$inputQuery =~ s/\s+/ /g;
$inputQuery =~ s/[^a-z 0-9:]+/ /g;
$inputQuery =~ s/\s+/ /g;
$inputQuery = &removeStopWord($inputQuery);
$inputQuery =~ s/\s+/ /g;
$inputQuery = &performStemming($inputQuery);
$inputQuery =~ s/\s+/ /g;
#print "Query after preprocessing:\n";
#print $inputQuery."\n";
return $inputQuery;
}

$query = &queryPreprocessing($query);

#print "$query";

my @queryList = split(/\s+/,$query);
my $N = 0;

opendir(INPUTDIR,$inputDir) or die($inputDir," directory doesn't exists.");

foreach $file ( grep(/\.preprocess$/,readdir(INPUTDIR)))
{
#print $file."\n";
$N++;
$tempDocID = $file; #document ID
$doc = $inputDir."/".$file; #file path to read file content
my %wordcount = ();
open(MYFILE,$doc) or die("Unable to open file: ",$doc);
while(<MYFILE>){
		@words = split(/\W*\s+\W*/, $_);
		#print @word;
		foreach $word (@words){
			$wordcount{$word}++;
		}
	}
	close(MYFILE);
	#print "Done";
	my $frequency = 0;
	#print %wordcount;
	foreach $word (sort keys(%wordcount)){
		#print "hi";
		#printf "%20s  %d\n", $word, $wordcount{$word};
		$frequency = $wordcount{$word};
		if(exists $invertedTable{$word})
		{
			#get the hash from invertedTable using $word as key and 
			#print $tempDocID;
			my %temp = ();
			%temp = %{$invertedTable{$word}};
			#%temp = values %invertedTable{$word};
			#print %temp;
			$temp{$tempDocID} = $frequency;
			$invertedTable{$word} = \%temp;
			#update the frequesny of doc id 

		}else
		{
			#create a new hash using $word as key and another hash using docid and frequency
			my %hashTemp = ();
			#print $tempDocID;
			$hashTemp{$tempDocID} = $frequency;
			$invertedTable{$word} = \%hashTemp;
			#add to the invertedTable
		}


	}
	#foreach $word 
}
#compute IDF 
my %IDFHash = ();
foreach my $token (sort keys %invertedTable)
{
	%tempIDFHash = %{$invertedTable{$token}};
	$n = keys %tempIDFHash;
	#print "size:".$n."::".log($N/$n)."\n";
	$IDFHash{$token} = log($N/$n)/(log (10));
}

#compute document length
#print "Starting DOC Lenght: \n";
my %docLengthHash = ();
my $wtd = 0;
foreach my $tk (sort keys %invertedTable)
{
	#print $tk;
	%tempDoc = %{$invertedTable{$tk}};
	@docLenList = sort keys (%tempDoc);

	foreach $docL (@docLenList)
	{
		#print $tk."::"."Tf in ".$docL."::".$tempDoc{$docL}."\n";
		#print $docL."\n";
		$wtd = $tempDoc{$docL} * $IDFHash{$tk};
		#print "wtd::".$wtd."\n";
		if(exists $docLengthHash{$docL})
		{
			$docLengthHash{$docL} += $wtd * $wtd;

		}
		else
		{
			$docLengthHash{$docL} = $wtd * $wtd;

		}

	}
}
#calcualte sqrt of document length
foreach my $d (sort keys %docLengthHash)
	{
 	$docLengthHash{$d} = sqrt($docLengthHash{$d});
 }

 #calculate numeratot for cosine similarity 
 my %documentNumerator = ();
my $qDen = 0;

#calcualte numerator
foreach my $wo (@queryList)
{
	if(exists $invertedTable{$wo})
	{
		my %matchDoc = %{$invertedTable{$wo}};
		my @docList = sort keys (%matchDoc);
		#print @docList."\n";
		#print "Size::",($#docList + 1)."\n";
		my $idf = ${IDFHash{$wo}};
		#print "IDF::".$idf."\n";
		#my $idf = log($N/($#docList+1));
		#print "IDF::",$idf."\n";
		$qDen += (1 * $idf) * (1* $idf);
		#print "QDen:".$qDen;
		foreach $d (@docList)
		{
			#print $d."\n";
			#print $wo."::".${matchDoc{$d}}."\n";
			if(exists $documentNumerator{$d})
			{
				#update frequency
				$freq  = ${matchDoc{$d}};
				$oldValue = $documentNumerator{$d};
				#assuming frequency of each query is one
				#print "Query:\n",$qDen;
				#print $qDen."\n";
				$weight = $freq * $idf;
				$documentNumerator{$d} = $weight * (1* $idf) + $oldValue;
				
			}
			else
			{
				#create new hash and assign to 
				$fr = ${matchDoc{$d}};
				$wt = $fr * $idf;
				$documentNumerator{$d} = $wt * (1 * $idf);
				#$qDen = (1 * $idf) * (1 * $idf); #assuming frequency of each query is one

			}

		}
	#print %matchDoc;
	}
}

#load map file
my $mapFilePath = "mappingfile";
my $mapFileLocation = $mapFilePath."/map.txt";
#print $mapFileLocation;
my %mapUrlHash = ();
open(INPUTFILE, $mapFileLocation);
while(<INPUTFILE>){
	chomp;
	my $line = $_;
	my @lineList = split(/\[]+/,$line);
	$mapUrlHash{$lineList[1]} = $lineList[0];
	
}
close(INPUTFILE);

 foreach $fileID (sort keys %mapUrlHash)
 {
 	#print $fileID."\n";
	#print $mapUrlHash{$fileID}."\n";
 }

#calculate similarity hash with query 
my %similarityHash = ();
my $score = 0;
my @finalList = keys (%documentNumerator);
foreach $fl (@finalList)
{
	#print $fl."\n";
	#print $qDen."\n";
	$score = $documentNumerator{$fl} / (${docLengthHash{$fl}} * sqrt($qDen));
	$similarityHash{$fl} = $score;
}


my @keysList = sort { $similarityHash{$b}<=> $similarityHash{$a} } keys %similarityHash;

foreach $ssafd (@keysList)
{
	#print $ssafd;
	#print $mapUrlHash{$ssafd};
}

#my $url = "http://google.com";
print "<table border='1'>";
print "<tr>";
print "<th> Cosine Similarity score</th>";
print "<th> Found in document </th>";
print "<th> URL </th>";
print "</tr>";
foreach $sim (@keysList)
	{
		#my $url = $mapUrlHash{$sim};
		#print "$url";
		print "<tr>";
		#print "<br></br>";
		#if(${similarityHash{$sim}}>0.0006) 
		#{
		print "<td> ${similarityHash{$sim}} </td>";
		print "<td> $sim </td>";
		print "<td> <a href='$mapUrlHash{$sim}'>$mapUrlHash{$sim}</a></td>";
		print "</tr>";
		#}
	}
print "</table>";
