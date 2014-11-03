#!/usr/bin/env perl

use utf8;
use Google::Search;
use LWP::UserAgent;
use Getopt::Long;
use HTML::ContentExtractor;
use Text::Language::Guess;
use LWP::Protocol::https;
use Lingua::Stem;
use Text::Ngrams;
use Class::CSV;

my $query = "perl modules"; # requete par defaut
my $guess = 0;
my $stem = 0;
my $export_file = "ckl_results.txt";
my $csvfile = 0;
my $pages = 50; #nombre de pages par defaut

GetOptions ('query=s' => \$query, 'pages=p' => \$pages,'guess' => \$guess, 'stem' => \$stem, 'csvfile' => \$csvfile) 
or die("Erreur dans les arguments (syntaxe d'une requete : --query=\"la requete\", pour choisir le nombre de pages : --number=n, pour determiner la langue : --guess, pour utiliser le stemmer : --stem, pour faire un export csv : --csvfile)\n");

my $agent = LWP::UserAgent->new();
my $extractor = HTML::ContentExtractor->new();
my $search = Google::Search->new(query=>$query,service=>web);
my $guesser = Text::Language::Guess->new();
my $stemmer = Lingua::Stem->new();
my $ng = Text::Ngrams->new(type => word, windowsize => 3);
my $count = 0;

while ((my $result = $search->next) && ($count < $pages)) {
    $uri = $result->uri;
    print "\n", $result->rank, " ", $uri, "\n";
    $count++;
    my $response = $agent->get($result->uri);
    
    if ($response->is_success) {
        $dec_cont = $response->decoded_content;
        $extractor->extract($uri,$dec_cont);
        $text = $extractor->as_text();
        my$lang;
        
        if($text) {
			my @text_array = split(/\s/,$text);
			my $joined_text = join(' ',@text_array);
            if($guess != 0) {
                $lang = $guesser->language_guess_string($joined_text);
                print "La langue est certainement : ", $lang, "\n";
            }
            
			if($stem != 0) {
				my @text_array = split(/\s/,$text);
				my $locale = 'en'; #langue par defaut
				if($lang) {
					$locale = $lang;
				}
				
				$stemmer->set_locale($locale);
	            		my @stemmed_words = @{$stemmer->stem(@text_array)};
	            		$ng->process_text(join(' ',@stemmed_words));
			}
			
			else {
				$ng->process_text($text);
			}
        }

        else {
            print "Page sans bloc de texte\n";
            $count--;
        }
    }
    
    else {
        warn $response->status_line;
        $count--;
    }
}
my @ngram_array = $ng->get_ngrams(orderby=>frequency);

# AFFICHAGE DES RESULTATS
my @lines = split('\n',$ng->to_string(orderby=>frequency));

# EXPORT DES RESULTATS
unless(open FILE, '>'.$export_file){
	die "Impossible d'ouvrir le fichier $export_file";
}
print $ng->to_string(orderby=>frequency, out=>$export_file);
close FILE;
print "Le resultat a ete enregistre dans le fichier ckl_resultats.txt.\n";

if($csvfile != 0) {		
	# creation des buffers CSV
	my $csv1 = Class::CSV->new (fields => ["unigram","frequency"]);
	$csv1->add_line(["unigram","frequency"]);

	my $csv2 = Class::CSV->new (fields => ["bigram","frequency"]);
	$csv2->add_line(["bigram","frequency"]);

	my $csv3 = Class::CSV->new (fields => ["trigram","frequency"]);
	$csv3->add_line(["trigram","frequency"]);

	my $indicator = 0;
	# remplissage des buffers csv
	my $line = shift @lines;
	
	while(!($line =~ /2-GRAMS \(total count: (\d)*\)/)){
		if ($line =~ /([A-Z]+|-)/ && $indicator < 5){
			$indicator++;
		}
		if ($indicator > 4){
			$csv1->add_line([split('\t',$line)]);
		}
		$line = shift @lines;
	}
	
	$indicator = 0;
	while(!($line =~ /3-GRAMS \(total count: (\d)*\)/)){
		if ($line =~ /([A-Z]+|-)/ && $indicator < 5){
			$indicator++;
		}
		if ($indicator > 4){
			$csv2->add_line([split('\t',$line)]);
		}
		$line = shift @lines;

	}
	
	$indicator = 0;
	while(!($line =~ /END OUTPUT BY Text::Ngrams/)){
		if ($line =~ /([A-Z]+|-)/ && $indicator < 5){
			$indicator++;
		}
		if ($indicator > 4){
			$csv3->add_line([split('\t',$line)]);
		}
		$line = shift @lines;
	}
	
	
	# creation des fichiers CSV

	open my $fh1, ">:encoding(utf8)", "ckl_unigram.csv" or die "ckl_unigram.csv: $!";
	open my $fh2, ">:encoding(utf8)", "ckl_bigram.csv" or die "ckl_bigram.csv: $!";
	open my $fh3, ">:encoding(utf8)", "ckl_trigram.csv" or die "ckl_trigram.csv: $!";

	my $csv_string1 = $csv1->string();
	my $csv_string2 = $csv2->string();
	my $csv_string3 = $csv3->string();

	print $fh1 $csv_string1;
	print $fh2 $csv_string2;
	print $fh3 $csv_string3;

	close $fh1;
	close $fh2;
	close $fh3;
	print "Les resultat ont ete enregistres dans 3 fichiers ckl_*grams.csv.\n";

}

=head1 NAME
projet_ckl.pl - Analyse des 50 reponses de Google
=head1 SYNOPSIS
projet_ckl.pl
projet_ckl.pl --query="cute puppies" --guess --stem
Options:
--query Ce qu'on cherche sur Google.
--guess Si on veut determiner la langue.
--stem Si on veut utiliser un stemmer.
--csvfile Si on veut exporter les n-grammes dans des fichiers .csv.
=head1 DESCRIPTION
Ce programme envoie une requete a Google,
recupere les 50 premieres reponses, extrait le texte des pages,
determine la langue (optionnel), lemmatise tous les mots (optionnel)
et effectue une analyse en bigrammes et trigrammes.
Si demande, il exporte les n-gram dans des fichiers csv separes.
=cut
