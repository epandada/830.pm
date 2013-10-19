package badianban;
use Dancer ':syntax';
use DateTime;


our $VERSION = '0.1';

get '/*?' => sub {
	template 'index';
};

get '/view/:date/:event' => sub{
	my $date = param('date');
	my $event = param('event');
	#read all folders
	opendir my($dh), config->{base_dir} . '/' . $date . '_' . $event  or die "Couldn't open dir $date $event: $!";
	my @files = readdir $dh;
	closedir $dh;
	my $result = [];
	#print files...
	foreach(@files){
		push @$result,config->{http_dir} . '/' . $date . '_' . $event . '/' . $_ if (($_ ne '.') && ($_ ne '..') && ($_ ne 'thumbnail.jpg'));
	}
	template 'detail', {result=>$result,date=>$date,event=>$event},{layout=>'slide'};
};

get '/view/:date' => sub{
	my $date = param('date');
	#read all folders
	opendir my($dh), config->{base_dir} or die "Couldn't open dir $date: $!";
	my @folders = readdir $dh;
	closedir $dh;
	my $events = {};
	#print files...
	foreach(@folders){
		my $regx = $date.'_([\w\d-]*)';
		my $folder_name = $_;
		if($_ =~ /^$regx/){
			my $name = $1;
			$events->{$name} = config->{http_dir} . '/' . $folder_name . '/thumbnail.jpg';
		}
	}
	template 'list', {events=>$events,date=>$date}
};

post '/api/upload' => sub {
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
	my $folder_path = config->{base_dir} . '/' . $dt->ymd . '_' . $dt->hms('-');;
	
	#check if folder exist
	unless(-d  $folder_path){
		mkdir $folder_path;
	}
	#save file
	my $cmd = 'mv -f ' . $upload->{tempname} . ' ' . $folder_path . '/' . $upload->{filename};
	`$cmd`;
	#create thumbnail
	$cmd = 'cp -f ' . $folder_path . '/' . $upload->{filename} . ' ' . $folder_path . '/thumbnail.jpg';
	`$cmd`;
	return to_json {status=>1,message=>"Upload Success!"};
};


true;
