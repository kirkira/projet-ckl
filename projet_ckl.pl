#!/usr/bin/env perl

use utf8;
use Google::Search;
use LWP::UserAgent;
use Getopt::Long;
use HTML::ContentExtractor;

my $query = "perl modules";       # requete par defaut

GetOptions ('query=s' => \$query) 
or die("Erreur dans les arguments (syntaxe d'une requete : --query=\"la requete\")\n");

my $agent = LWP::UserAgent->new();
my $extractor = HTML::ContentExtractor->new();
my $search = Google::Search->new(query=>$query,service=>web);
my $count = 0;

while ((my $result = $search->next) && ($count < 50)) {
	
	$uri = $result->uri;
    #print $result->rank, " ", $uri, "\n";
    $count++;
    my $response = $agent->get($result->uri);
    
    if ($response->is_success) {
		$dec_cont = $response->decoded_content;
		#print $dec_cont;
		$extractor->extract($uri,$dec_cont);
		$text = $extractor->as_text();
		#print text;
		# continuer ici l'analyse de $text ...
	}
	else {
		warn $response->status_line;
	}
} 

=head1 NAME
projet_ckl.pl - Analyse des 50 reponses de Google

=head1 SYNOPSIS
projet_ckl.pl
projet_ckl.pl --query="cute puppies"
Options:
--query Ce qu'on cherche sur Google.

=head1 DESCRIPTION
Ce programme envoie une requete a Google, recupere les 50 premieres reponses,
extrait le texte des pages, determine la langue, lemmatise tous les mots et effectue un analyse 
en bigrammes et trigrammes.
=cut
