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

my $query = "perl modules"; # requete par defaut
my $guess = 0;
my $stem = 0;
GetOptions ('query=s' => \$query, 'guess' => \$guess, 'stem' => \$stem)
or die("Erreur dans les arguments (syntaxe d'une requete : --query=\"la requete\", pour determiner la langue : --guess, pour utiliser le stemmer : --stem)\n");

my $agent = LWP::UserAgent->new();
my $extractor = HTML::ContentExtractor->new();
my $search = Google::Search->new(query=>$query,service=>web);
my $guesser = Text::Language::Guess->new();
my $stemmer = Lingua::Stem->new();
$stemmer->stem_caching({-level => 2});
my $ng = Text::Ngrams->new(type => word, windowsize => 2);
my $count = 0;

while ((my $result = $search->next) && ($count < 50)) {
    $uri = $result->uri;
    print "\n", $result->rank, " ", $uri, "\n";
    $count++;
    my $response = $agent->get($result->uri);
    
    if ($response->is_success) {
        $dec_cont = $response->decoded_content;
        $extractor->extract($uri,$dec_cont);
        $text = $extractor->as_text();
        my $lang;
        
        if($text) {
            if($guess == 1) {
                # Guess language
                $lang = $guesser->language_guess_string($text);
                print "La langue est certainement : ", $lang, "\n";
            }
            
			if($stem == 1) {
				my @text_array = split(' ',$text);
				my $locale = 'en';
				if($lang) {
					$locale = $lang;
				}
				
				$stemmer = set_locale($locale);
	            my $stemmed_words_anon_array = $stemmer->stem(@text_array);
	            $ng->process_text(join(' ',$stemmed_words_anon_array));
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

# AFFICHAGE DES RESULTATS:
print $ng->to_string(orderby=>frequency);

=head1 NAME
projet_ckl.pl - Analyse des 50 reponses de Google
=head1 SYNOPSIS
projet_ckl.pl
projet_ckl.pl --query="cute puppies" --guess --stem
Options:
--query Ce qu'on cherche sur Google.
--guess Si on veut determiner la langue.
--stem Si on veut utiliser un stemmer.
=head1 DESCRIPTION
Ce programme envoie une requete a Google,
recupere les 50 premieres reponses, extrait le texte des pages,
determine la langue (optionnel), lemmatise tous les mots (optionnel)
et effectue une analyse en bigrammes et trigrammes.
=cut
