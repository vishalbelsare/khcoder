package kh_at::transf;
use base qw(kh_at);
use strict;

sub _exec_test{
	my $self = shift;

	# HTMLからCSVへの変換
	$self->{result} .= "■HTMLからCSVへの変換\n";
	foreach my $tani ('bun','dan','h2'){
		mysql_html2csv->exec(
			tani => $tani,
			file => $self->file_out_tmp_base."_$tani.txt"
		);
		$self->{result} .= 
			"$tani: "
			.$self->get_md5($self->file_out_tmp_base."_$tani.txt")
			."\n"
		;
		unlink($self->file_out_tmp_base."_$tani.txt") or die;
	}

	# 部分テキストの取り出し
	$self->{result} .= "■部分テキストの取り出し\n";

	$self->{result} .= "□見出しの取り出し\n";
	my %midashi;
	$midashi{h2} = 1;
	mysql_getheader->get_all(
		file     => $self->file_out_tmp_base."_pm1.txt",
		pic_head => \%midashi,
	);
	$midashi{h1} = 1;
	mysql_getheader->get_all(
		file     => $self->file_out_tmp_base."_pm2.txt",
		pic_head => \%midashi,
	);

	$self->{result} .= 
		"H2: "
		.$self->get_md5($self->file_out_tmp_base."_pm1.txt")
		."\n"
	;
	$self->{result} .= 
		"H1 & H2: "
		.$self->get_md5($self->file_out_tmp_base."_pm2.txt")
		."\n"
	;

	unlink($self->file_out_tmp_base."_pm1.txt") or die;
	unlink($self->file_out_tmp_base."_pm2.txt") or die;

	$self->{result} .= "□コーディングルールによる取り出し\n";

	my $cod_obj = kh_cod::pickup->read_file($self->file_cod) or return 0;
	$cod_obj->pick(
		file     => $self->file_out_tmp_base."_pc1.txt",
		selected => 2,
		tani     => 'dan',
		pick_hi  => 0,
	);
	$cod_obj->pick(
		file     => $self->file_out_tmp_base."_pc2.txt",
		selected => 2,
		tani     => 'h2',
		pick_hi  => 1,
	);

	$self->{result} .= 
		"dan: "
		.$self->get_md5($self->file_out_tmp_base."_pc1.txt")
		."\n"
	;
	$self->{result} .= 
		"H2: "
		.$self->get_md5($self->file_out_tmp_base."_pc2.txt")
		."\n"
	;

	unlink($self->file_out_tmp_base."_pc1.txt") or die;
	unlink($self->file_out_tmp_base."_pc2.txt") or die;

	return $self;
}

sub test_name{
	return 'file transf...';
}

1;