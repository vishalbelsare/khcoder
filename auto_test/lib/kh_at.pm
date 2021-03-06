package kh_at;

use strict;
use Text::Diff;
use Digest::MD5;
use kh_at::project_new;
use kh_at::pretreatment;
use kh_at::words;
use kh_at::out_var;
use kh_at::cod;
use kh_at::transf;
use kh_at::docs;

sub exec_test{
	my $class = shift;
	my $self;
	$self->{file_base} = shift;
	bless $self, $class;
	
	$self->_exec_test;
	$self->_write_result;
	$self->_check_output;
	
	return 1;
}

sub _check_output{
	my $self = shift;
	
	my $print_buffer = ">>> ";
	$print_buffer .= $self->test_name." ";
	
	my $diff = diff(
		$self->file_test_output,
		$self->file_test_ref,
		{ STYLE => 'Context' }
	);
	
	if ($diff){
		$print_buffer .= "\tNG\n";
		my $file = $self->file_test_output.'_diff.txt';
		open(OUT,">$file") or die;
		print OUT $diff;
		close (OUT);
	} else {
		$print_buffer .= "\tOK\n";
	}
	
	print STDERR $print_buffer;
	
	return 1;
}

sub _write_result{
	my $self = shift;
	my $out_file = $self->file_test_output;
	
	$self->{result} =~ s/\r//go;
	
	open (OUTF,">$out_file") or die;
	print OUTF $self->{result};
	close (OUTF);
}

#--------------------------------#
#   テスト用プロジェクトの操作   #

sub close_test_project{
	$::main_gui->{menu}->mc_close_project;
}

sub open_test_project{
	gui_window::project_open->open;
	my $win_opn = $::main_gui->get('w_open_pro');
	my $n = @{$win_opn->projects->list} - 1;
	$win_opn->{g_list}->selectionClear(0);
	$win_opn->{g_list}->selectionSet($n);
	$win_opn->_open;
}

sub delete_test_project{
	gui_window::project_open->open;
	my $win_opn = $::main_gui->get('w_open_pro');
	my $n = @{$win_opn->projects->list} - 1;
	$win_opn->{g_list}->selectionClear(0);
	$win_opn->{g_list}->selectionSet($n);
	$win_opn->delete;
	$win_opn->close;
}

#----------------------#
#   ユーティリティー   #

sub get_md5{
	my $self = shift;
	my $path = shift;

	open (CHKF,"$path") or die;
	binmode(CHKF);
	my $md5 = Digest::MD5->new->addfile(*CHKF)->hexdigest;
	close (CHKF);

	return $md5;
}

#--------------#
#   アクセサ   #

sub file_testdata_org{
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/data_input/kokoro2.txt';
	return $file;
}

sub file_testdata{
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/data_input/kokoro2_.txt';
	return $file;
}

sub file_test_output{
	my $self = shift;
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/'.$self->{file_base}.'.txt';
	return $file;
}

sub file_test_ref{
	my $self = shift;
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/data_ref/'.$self->{file_base}.'.txt';
	return $file;
}

sub file_outvar{
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/data_input/out_var.csv';
	return $file;
}

sub file_outvar2{
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/data_input/out_var2.csv';
	return $file;
}

sub file_cod{
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/data_input/theme.cod';
	return $file;
}

sub file_out_tmp_base{
	use Cwd qw(cwd);
	my $file = cwd.'/auto_test/hoge';
	return $file;
}


1;