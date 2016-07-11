# @copyright (c) 2016 Kentaro SATO
# @license MIT License

use 5.014;
use warnings;
use utf8;
use FindBin qw($Bin);

my $fw = '';
my $fwa = '';
my %aprops;

my $table = shift(@ARGV);
die "usage: perl $0 EastAsianWidth.txt > regex.txt\n" if (!$table || $table !~ /\bEastAsianWidth\b/ || @ARGV);

my $copyrightPath = $Bin . '/unicode-copyright.txt';

my $ambiProp = qr/^Co$/;
my $ambiPat = qr/[АБВГДЕЖЗИЙКЛМНОПРСТУФХЦЧШЩЪЫЬЭЮЯабвгдежзийклмнопрстуфхцчшщъыьэюяǎǐǒǔǖǘǚǜαβγδεζηθικλμνξοπρστυφχψωёˊˋˍΑΒΓΔΕΖΗΘΙΚΛΜΝΞΟΠΡΣΤΥΦΧΨΩЁÅⅠⅡⅢⅣⅤⅥⅦⅧⅨⅩⅪⅫⅰⅱⅲⅳⅴⅵⅶⅷⅸⅹ①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳⑴⑵⑶⑷⑸⑹⑺⑻⑼⑽⑾⑿⒀⒁⒂⒃⒄⒅⒆⒇⒈⒉⒊⒋⒌⒍⒎⒏⒐⒑⒒⒓⒔⒕⒖⒗⒘⒙⒚⒛⓫⓬⓭⓮⓯⓰⓱⓲⓳⓴⓵⓶⓷⓸⓹⓺⓻⓼⓽⓾❶❷❸❹❺❻❼❽❾❿‐―’”‘“§¶‖†‡‥…‰′″※¨´±×÷←↑→↓⇒⇔∀∂∃∇∈∋∑√∝∞∟∠∥∧∨∩∪∫∬∮∴∵∽≒≠≡≦≧≪≫⊂⊃⊆⊇⊥⊿♯°℃№℡⌒⒜⒝⒞⒟⒠⒡⒢⒣⒤⒥⒦⒧⒨⒩⒪⒫⒬⒭⒮⒯⒰⒱⒲⒳⒴⒵ⒶⒷⒸⒹⒺⒻⒼⒽⒾⒿⓀⓁⓂⓃⓄⓅⓆⓇⓈⓉⓊⓋⓌⓍⓎⓏⓐⓑⓒⓓⓔⓕⓖⓗⓘⓙⓚⓛⓜⓝⓞⓟⓠⓡⓢⓣⓤⓥⓦⓧⓨⓩ─━│┃┌┏┐┓└┗┘┛├┝┠┣┤┥┨┫┬┯┰┳┴┷┸┻┼┿╂╋■□▲△▼▽◆◇○◎●◯★☆☉☎☏☜☞♀♂♪♭✽]/;

open(my $fp, '<:utf8', $copyrightPath) or die;
read($fp, my $copyright, -s $copyrightPath) or die;
binmode(STDOUT, ':raw:utf8');
open($fp, '<', $table) or die;
while (<$fp>) {
	next if ($_ =~ /^#|^$/);
	my ($from, $to, $type, $prop) = $_ =~ /^([0-9A-F]{4,6})(?|()|\.\.([0-9A-F]{4,6}));(\w+)\s*# (\S\S) / or die;
	next if ($type =~ /^(?:[NH]|Na)$/);
	die if ($type !~ /^[WFA]$/);
	$from = hex($from);
	$to = $to ? hex($to) : $from;
	next if ($from >= 0x10000);
	$to = 0xffff if ($to >= 0x10000);
	$from = chr($from);
	$to = chr($to);
	die "the current dumb implementation cannot process hyphen-minus correctly" if ("$from$to" =~ /-/);
	if ($type =~ /^A/) {
		$aprops{$prop} //= '';
		appendRangeString($aprops{$prop}, $from, $to);
	}
	appendRangeString($fw, $from, $to) if ($type =~ /^[WF]/);
	if ($type =~ /^[WF]/ || ($type eq 'A' && $prop =~ $ambiProp)) {
		appendRangeString($fwa, $from, $to);
	} elsif ($type eq 'A') {
		$from = ord($from);
		$to = ord($to);
		for (my $code = $from; $code <= $to; $code++) {
			if (chr($code) =~ $ambiPat) {
				appendRangeString($fwa, chr($code), chr($code));
			}
		}
	}
}
close($fp);
trimRangeString($fw);
trimRangeString($fwa);
foreach my $prop (keys %aprops) {
	expandRangeString($aprops{$prop})
}

say $copyright;
say "fw: [$fw]";
say "fwa: [$fwa]";

say "";
foreach my $prop (sort keys %aprops) {
	say "$prop: $aprops{$prop}";
}


sub appendRangeString {
	if ($_[0] ne '') {
		if (ord(substr($_[0], -1)) == ord($_[1]) - 1) {
			substr($_[0], -1) = $_[2];
			return;
		}
	}
	$_[0] .= "$_[1]-$_[2]";
}

sub trimRangeString {
	$_[0] =~ s/([^-])-\1/$1/g;
	$_[0] =~ s/(\P{Print})/sprintf('\\u%04x', ord($1))/eg;
}

sub expandRangeString {
	$_[0] =~ s/([^-])-([^-])/
		my $from = ord($1);
		my $to = ord($2);
		my $string = '';
		for (my $code = $from; $code <= $to; $code++) {
			$string .= chr($code);
		}
		$string;
	/eg;
}
