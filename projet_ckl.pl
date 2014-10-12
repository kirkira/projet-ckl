#!/usr/bin/env perl

use utf8;
use Google::Search;
use LWP::UserAgent;
use Getopt::Long;
use HTML::ContentExtractor;
use Text::Language::Guess;
use LWP::Protocol::https;

my $query = "perl modules";       # requete par defaut
my $guess = 0;
GetOptions ('query=s' => \$query, 'guess' => \$guess) 
or die("Erreur dans les arguments (syntaxe d'une requete : --query=\"la requete\", pour determiner la langue : --guess)\n");

my $agent = LWP::UserAgent->new();
my $extractor = HTML::ContentExtractor->new();
my $search = Google::Search->new(query=>$query,service=>web);
my $guesser = Text::Language::Guess->new();
my $count = 0;

while ((my $result = $search->next) && ($count < 50)) {
	
	$uri = $result->uri;
    print "\n", $result->rank, " ", $uri, "\n";
    $count++;
    my $response = $agent->get($result->uri);
    
    if ($response->is_success) {
		$dec_cont = $response->decoded_content;
		#print $dec_cont;
		$extractor->extract($uri,$dec_cont);
		$text = $extractor->as_text();
		#print $text;
		if($text) {
			if($guess == 1) {
			# Guess language
			my $lang = $guesser->language_guess_string($text);
			print "La langue est certainement : ", $lang, "\n";
			}
		
		# continuer ici l'analyse de $text ...
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

=head1 NAME
projet_ckl.pl - Analyse des 50 reponses de Google

=head1 SYNOPSIS
projet_ckl.pl
projet_ckl.pl --query="cute puppies" --guess
Options:
--query Ce qu'on cherche sur Google.
--guess Si on veut determiner la langue.

=head1 DESCRIPTION
Ce programme envoie une requete a Google, 
recupere les 50 premieres reponses, extrait le texte des pages, 
determine la langue (optionnel), lemmatise tous les mots
et effectue une analyse en bigrammes et trigrammes.
=cut
