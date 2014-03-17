#/usr/bin/perl
use CGI;
use LWP::Simple;
use Text::English; #PStemmer 

my $inputDir = "inputfile";
my %invertedTable = (); #main inverted table

my $q = CGI->new;
my $val = $q->param('sendData0');

print $q->header;

my $query = "memphis library";
print "Your Entered:: $val \n";
#print $query;

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

#subroutine handles morpholical variation
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
#print "Query after preprocessing:\n";
#print $query."\n";
my @queryList = split(/\s+/,$query);
#print @queryList;
#foreach $a (@queryList)
#	{
#	print $a."\n";
#	}
#load an inverted index find the document containting these key words
#print $inputDir;
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
#print "Total Doc:",$N."\n";

foreach my $word (sort keys %invertedTable){
		#print "Keys::",$word;
		foreach my $w (@queryList)
		{
			if($w eq $word)
			{
				%tempTable = %{$invertedTable{$word}};
				#print $word,":";
				foreach my $docID (keys %tempTable){
							#print $docID,"=>",$tempTable{$docID},"  ";

										}
				#print "\n";
			}
		}
		#%tempTable = %{$invertedTable{$word}};
		#print $word,":";
	

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

#print "IDF: \n";
my @idflist = keys (%IDFHash);
foreach $id (@idflist)
	{
		#print $id."::".${IDFHash{$id}}."\n";
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
#print "Document Lenght: \n";
my @doclist = keys (%docLengthHash);
foreach $id (@doclist)
	{
		#print $id.":###:".$docLengthHash{$id}."\n";
	}

 foreach my $d (sort keys %docLengthHash)
	{
 	$docLengthHash{$d} = sqrt($docLengthHash{$d});
 }

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

#print "Numerator: \n";
# my @numlist = keys (%documentNumerator);
# foreach $dd (@numlist)
# 	{
# 		#print $dd."::".${documentNumerator{$dd}}."\n";
# 	}

#print "Similarity Score: \n";
my @keysList = sort { $similarityHash{$b}<=> $similarityHash{$a} } keys %similarityHash;

foreach $sim (@keysList)
	{
		print $sim."::".${similarityHash{$sim}}."\n";
	}


