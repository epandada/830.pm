use v5.12;
use CGI; # This is a quick demo. I recommend Plack/PSGI for production.
use Imager::QRCode;

my $q = CGI->new;
my $text = '111';
if (defined $text) {
    my $qrcode = Imager::QRCode->new(
        size          => 5,
        margin        => 5,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new(255, 255, 255),
        darkcolor     => Imager::Color->new(0, 0, 0),
    );
    my $img = $qrcode->plot($text);
    $img->write(file=>'111.png', type => 'png')
        or die $img->errstr;
} else {
    print $q->header('text/html');
    print <<END_HTML;
<!DOCTYPE html>
<meta charset="utf-8">
<title>QR me</title>
<h1>QR me</h1>
<form>
    <div>
        <label>
            What text should be in the QR code?
            <textarea name="text"></textarea>
        </label>
        <input type="submit">
    </div>
</form>
END_HTML
}