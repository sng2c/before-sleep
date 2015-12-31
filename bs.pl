#!/usr/bin/env perl

use utf8;
use Mojolicious::Lite;
use Data::Dumper;
use File::Basename;
use Archive::Zip;
use Archive::Zip::MemberRead;
use JSON;
use Image::Size;
use File::Slurp;

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

get '/' => sub {
	my $c = shift;
	my $curpath = $c->param('p');
	$curpath ||= $datapath;
	my @files = <$curpath/*>;
	@files = map{ utf8::decode($_); $_; } @files;
	@files = map{ 
		my $dir = -d $_;
		my ($name, $path, $ext) = fileparse($_, qr/\.[^.]*/); 
		{name=>$name, path=>$path, ext=>lc($ext), is_dir=>$dir, orig=>$_};
	} @files;
	@files = grep{$_->{name} ne 'meta'}@files;

	$c->render(template => 'index', files=>\@files);
};

get '/view' => sub{
	my $c = shift;
	my $zipfile = $c->param('p');
	my $dir = dirname($zipfile);
	my $meta;
	eval{
		$meta = decode_json(read_file($dir.'/meta.json'));
	};
	my $direction = 1;
	if($meta){
		$direction = $meta->{direction};
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
	print Dumper @members;


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
