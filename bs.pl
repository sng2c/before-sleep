#!/usr/bin/env perl
use v5.10;
use utf8;
use Mojolicious::Lite;
use Data::Dumper;
use File::Basename;
use Archive::Zip;
use Archive::Zip::MemberRead;
use JSON;
use Image::Size;
# Documentation browser under "/perldoc"
plugin 'PODRenderer';
plugin "bootstrap3" => {
    theme => {
        paper => "http://bootswatch.com/paper/_bootswatch.scss",
        slate => "http://bootswatch.com/slate/_bootswatch.scss",
        darkly => "http://bootswatch.com/darkly/_bootswatch.scss",
    },
};
plugin "FontAwesome4";

my $datapath = './data';

sub nsort{
	my ($a, $b) = @_;
	my @a = split(/(\d+)/,$a);
	my @b = split(/(\d+)/,$b);

	my $res = 0;

	my $lena = @a;
	my $lenb = @b;

	my $minlen = $lena<$lenb?$lena:$lenb;

	foreach my $i (0..$minlen){
		my $aa = $a[$i];
		my $bb = $b[$i];
		my $anum = $aa=~/^\d+$/;
		my $bnum = $bb=~/^\d+$/;
		my $subres = 0;
		if($anum && $bnum){
			$subres = $aa <=> $bb;
		}
		else{
			$subres = $aa cmp $bb;
		}
		return $subres if $subres != 0
	}
	return $lena <=> $lenb;
}

get '/' => sub {
	my $c = shift;
	my $curpath = $c->param('p');
	$curpath ||= $datapath;
	opendir(DIR, $curpath);
	my @files = readdir(DIR);
	closedir(DIR);
	
	@files = map{ utf8::decode($_); $_; } @files;
	@files = grep{ $_ !~ /^\./ }@files;
	@files = map{ $curpath.'/'.$_; }@files;

	@files = map{ 
		my $dir = -d $_;
		my ($name, $path, $ext) = fileparse($_, qr/\.[^.]*/);
		{name=>$name, path=>$path, ext=>lc($ext), is_dir=>$dir, orig=>$_, prior=>$dir?0:ord($ext)+1};
	} @files;



	@files = sort{ $a->{prior} <=> $b->{prior} || nsort($a->{'name'}, $b->{'name'}) }@files;
	

	my $tmppath = $curpath;
	$tmppath =~ s/^\Q$datapath\E//;

	my @paths = grep {$_;} split(/[\\\/]/,$tmppath);
	
	my @pp;
	my $lastpath = $datapath;

	foreach my $p (@paths){
		$lastpath .= '/'.$p;
		push(@pp,{path=>$lastpath, name=>$p});
	}
	$c->render(template => 'index', files=>\@files, paths=>\@pp);
};

get '/view' => sub{
	my $c = shift;
	my $zipfile = $c->param('p');
	my $dir = dirname($zipfile);
	my $direction = 1;
	if(-f $dir.'/LEFT'){
		$direction = -1;
	}
	$c->render(template => 'view', file=>$zipfile, dir=>$dir, direction=>$direction);
};

get '/zip_list' => sub{
	my $c = shift;
	my $zipfile = $c->param('p');
	my $dir = dirname($zipfile);


	my $zip = Archive::Zip->new($zipfile);
	my @members = $zip->members();
	@members = map{$_->fileName()}@members;


	$c->render(json=>{file=>$zipfile, dir=>$dir, members=>\@members});
};

get '/zip_img' => sub{
	my $c = shift;
	my $zipfile = $c->param('p');
	my $name = $c->param('n');
	my $size = $c->param('s');

	my ($n, $p, $ext) = fileparse($name, qr/\.[^.]*/); 
	$ext = lc($ext);
	$ext =~ /\.(.+?)$/;
	$ext = $1;

	my $dir = dirname($zipfile);

	my $zip = Archive::Zip->new($zipfile);
	my $mem = $zip->memberNamed($name);
	my $fh = $mem->readFileHandle();
	my $bytes = '';
	while (1){
		my $buffer;
		my $read = $fh->read($buffer, 4096);
		die "FATAL ERROR reading my secrets !\n" if (!defined($read));
		last if (!$read);
		$bytes .= substr $buffer, 0, $read;
	}
	$fh->close();
	$c->res->headers->append('Cache-Control','max-age=3600, must-revalidate');
	if($size){
		my ($x, $y, $id) = imgsize(\$bytes);
		$c->res->headers->append('X-IMAGE-WIDTH', $x);
		$c->res->headers->append('X-IMAGE-HEIGHT', $y);
		$c->render(text=>'ok');
	}
	else{
		$c->render(data => $bytes, format => $ext);
	}

};

app->start;
