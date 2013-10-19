package badianban;
use Dancer ':syntax';
use DateTime;
use Imager::QRCode;
use Getopt::Std;

our $VERSION = '0.1';

my %opts = (
    o => 'qrcode.png',         # Output filename
    e => 'M',                   # Error correction level
    s => '4',                   # Pixel size
    t => 'thumbnail.jpg',
);

sub _generateQRcode{
	my $str = shift;
	my $file = shift;
	getopt('o:e:s:', \%opts);
	my $qr = Imager::QRCode->new(
	    size =>  $opts{s},
	    level => $opts{e},
	);
	my $img = $qr->plot($str);
	$img->write( file => $file,type=>'png');
}

get '/:name?' => sub {
	my $name = param('name') || 'default';
	my $display_name = $name eq 'default' ? "你" : $name;
	#check if folder exists
	mkdir config->{base_dir} . $name unless(-d config->{base_dir} . $name);
	#generate qrcode
	my $file_full_path = config->{base_dir} . '/' . $name . '/' . $opts{o};
	_generateQRcode(request->uri_base . "/$name/view/all", $file_full_path);
	template 'index',{"message"=>"八点半了，$display_name 还在加班吗？",name=>$name};
};


get '/:name/view/:date/:event' => sub{
	my $name = param('name') || 'default';
	my $date = param('date');
	my $event = param('event');
	#read all folders
	opendir my($dh), config->{base_dir} . "/$name/". $date . '_' . $event  or return "Couldn't open dir $date $event: $!";
	my @files = readdir $dh;
	closedir $dh;
	my $result = [];
	#print files...
	foreach(@files){
		push @$result,config->{http_dir} . "/$name/" . $date . '_' . $event . '/' . $_ if (($_ ne '.') && ($_ ne '..') && ($_ ne $opts{t}) && ($_ ne $opts{o}));
	}
	_generateQRcode(request->uri_base . "/$name/view/$date/$event",config->{base_dir} . "/$name/". $date . '_' . $event . '/' . $opts{o});
	my $qrcode_url = "/data/$name/" . $date . '_' . $event . '/' . $opts{o};
	template 'detail', {result=>$result,date=>$date,event=>$event,message=>"<a href='/$name/view/$date'>返回</a>",qrcode_url=>$qrcode_url,name=>$name},{layout=>'main'};
};

get '/:name/view/:date' => sub{
	my $name = param('name') || 'default';
	my $date = param('date');
	#read all folders
	opendir my($dh), config->{base_dir}."/$name" or return "Couldn't open dir $date: $!";
	my @folders = readdir $dh;
	closedir $dh;
	my $events = {};
	#print files...
	foreach(@folders){
		my @folder_name = split(/_/,$_);
		if((scalar(@folder_name) == 2 && $date eq "all" && $folder_name[1] ne "Store") || ($date eq $folder_name[0])){
			$events->{$folder_name[1]}->{name} = config->{http_dir} . "/$name/" . join('_',@folder_name) . '/' . $opts{t};
			$events->{$folder_name[1]}->{link} = "/$name/view/" . $folder_name[0] . '/' . $folder_name[1];
			$events->{$folder_name[1]}->{title} = join(":",split(/-/,$folder_name[1]));
		}else{
		}
	}
	_generateQRcode(request->uri_base . "/$name/view/$date",config->{base_dir} . "/$name/" . $date . '.png');
	my $qrcode_url = "/data/$name/$date" . '.png';
	template 'list', {name=>$name,events=>$events,date=>$date,message=>"请选择你想查看的项目",qrcode_url=>$qrcode_url}
};

post '/api/upload/:name' => sub {
	my $name = param('name') || 'default';
	my $result = {};
	my $upload = request->upload('files');
	#check filename
	return to_json {status=>0,message=>'Empty File'} unless($upload->{filename});
	#check file extention, image
	return to_json {status=>0,message=>$upload->{headers}->{'Content-Type'}} unless($upload->{headers}->{'Content-Type'} =~/image\//);

	#check if base folder exist
	unless(-d  config->{base_dir}){
		mkdir config->{base_dir};
	}
	my $dt = DateTime->now(time_zone=>'local');
	my @hms = split(/-/,$dt->hms('-'));
	my $folder_path = config->{base_dir} . "/$name/" . $dt->ymd . '_' . $hms[0] . '-' . $hms[1];
	
	#check if folder exist
	unless(-d  $folder_path){
		mkdir $folder_path;
	}
	#save file
	my $cmd = 'mv -f ' . $upload->{tempname} . ' ' . $folder_path . '/' . $upload->{filename};
	`$cmd`;
	#create thumbnail
	$cmd = 'cp -f ' . $folder_path . '/' . $upload->{filename} . ' ' . $folder_path . '/' . $opts{t};
	`$cmd`;
	return to_json {status=>1,message=>"Upload Success!"};
};


true;
