#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper qw/Dumper/;
 
 
my $outfile= my $infile= $ARGV[0];
 
my $f_in;
if ($infile) {
  print "* Processing $infile => $outfile\n";
  open $f_in , "<", "$infile" ;
  
} else {
  $outfile="/tmp/test.pod";
  print "* Processing __DATA__ => $outfile\n"; 
  $f_in=\*DATA;
}
 
$outfile =~ s/\.org$/.pod/;
open my $f_out, ">", "$outfile";
 
 
my $out;
 
my $r_begin_src='^\s*#\+BEGIN_SRC:?\s*(.*)\s*$';
my $r_end_src = '^\s*#\+END_SRC\s*$';
 
print $f_out "\n=encoding utf8\n\n";
 
#--- First pass
while(<$f_in>) {
  #--- Codeblock?
  if ( /$r_begin_src/i .. /$r_end_src/i) {
    s/($r_end_src|$r_begin_src)/\n/i;
    $_=" $_";                           # add indentation
    s#\s*Listing{(\w+)}#listing_grep($1)#gie;
    
  } else {
    #--- Heading?
    if (s/^(\*+)(\s.*)/"\n=head".length($1)."$2\n"/e ) {
      #--- Heading == "__DATA__" ?
      last if $2 =~ /^\s*__DATA__\s*$/; #  stop parsing
 
    } else {
      #--- Textbody
      s/^\s+(\S)/$1/;                   # delete indentation
      s/^\s+$/\n/;                      # delete empty lines
      convert_markup();
    }
  }
  $out.=$_;
}
 
listing_dump();
 
#--- Second pass
$out =~   s#Listing{(\w+)}#listing_ref($1)#gie;
 
#--- Output
print $f_out $out;
 
##--- Process pod-file
#my $do=`make.pl $outfile`; 
 
exit;
 
 
# ----------------------------------------
sub convert_markup {
  my $in=$_;
  my $out;
 
  #--- ignore POD markups
  my $notPOD=0;                         # flipflop
  for (split /([CBIEZ]<.*?>)/,$in){      
    if ( $notPOD ^= 1 ) {               # odd => not Pod
      #--- translate
      s#/(.+?)/#I<$1>#g;                    # / -> Italic
      s#\*(.+?)\*#B<$1>#g;                  # * -> Bold
#      s#_(.+?)_#I<$1>#g;                   # _ -> Underline
 
      #--- add markup DWIM    
      s#(?<!<)(\w+(::\w+)+)(?!>)# L<$1> #g; # -> L<Mod::ule>
      s#([\$\%\@\&]\w+)#C<$1>#;             # -> C<$var>
    }
    $out.=$_;
  }
  $_=$out;
}       
 
 
 
 
# ----------------------------------------
# name and refrence listings by name 
 
# "LISTING{label}" in code -> incremented number
# "LISTING{label}" in text -> reference code listing
 
#  TODO:
#   * support org reference markup instead
#     like <<label>>  or (ref: label) 
#   * more checks for possible typos in labels
 
 
my %listing_nr;                        # Number hash
my $listing_c;                         # Counter
 
sub listing_dump {
  # check Listing hash
  print Dumper \%listing_nr;
}
 
sub listing_grep {
  my $name=uc(shift);                   # insensitif
  $listing_nr{$name} = ++$listing_c;  
  $name=qq{Listing $listing_c};
  $name= " "x(40-length($name)) .$name; # align right 
  return $name;
}
 
sub listing_ref {
  my $name=uc(shift);                   # insensitif
  $listing_c = $listing_nr{$name};
  warn "Listing $name unknown!" unless defined $listing_c;
  $name=qq{Listing $listing_c};
  return $name;
}
 
__DATA__
*  Example Org for testing
** heading 2
   Text in C<Path/path/path> might be /Italic/ or *Bold* and
   org-markup nested in POD-markup is I<*ignored*>.
   
  #+BEGIN_SRC Perl
  print("huhu") while(1);

 
  LISTING{huhu}
  #+END_SRC 
 
   bla bla ... and the code in LISTING{huhu} prints "huhu"
 
* __DATA__
this text will not be processed anymore 
 
