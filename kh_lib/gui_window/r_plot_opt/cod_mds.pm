package gui_window::r_plot_opt::cod_mds;
use base qw(gui_window::r_plot_opt);

sub innner{
	my $self = shift;
	my $lf = $self->{labframe};

	# ��ˡ
	my $fd = $lf->Frame()->pack(
		-fill => 'x',
		#-padx => 2,
		-pady => 4,
	);

	$fd->Label(
		-text => $self->gui_jchar('��ˡ��'),
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget = gui_widget::optmenu->open(
		parent  => $fd,
		pack    => {-side => 'left'},
		options =>
			[
				['Classical', 'C'],
				['Kruskal',   'K'],
				['Sammon',    'S'],
			],
		variable => \$self->{method_opt},
	);

	my $method = 'C';
	if ($self->{command_f} =~ /isoMDS/){
		$method = 'K';
	}
	elsif ($self->{command_f} =~ /sammon/){
		$method = 'S';
	}
	$widget->set_value($method);

	$fd->Label(
		-text => $self->gui_jchar('  ��Υ��'),
		-font => "TKFN",
	)->pack(-side => 'left');

	my $widget_dist = gui_widget::optmenu->open(
		parent  => $fd,
		pack    => {-side => 'left'},
		options =>
			[
				['Jaccard', 'binary'],
				['Euclid',  'euclid'],
				['Cosine',  'pearson'],
			],
		variable => \$self->{method_dist},
	);
	if ( $self->{command_f} =~ /euclid/ ){
		$widget_dist->set_value('euclid');
	}
	elsif  ( $self->{command_f} =~ /binary/ ){
		$widget_dist->set_value('binary');
	}
	else {
		$widget_dist->set_value('pearson');
	}

	# �����ο�
	my $fnd = $lf->Frame()->pack(
		-fill => 'x',
		-pady => 4,
	);

	$fnd->Label(
		-text => $self->gui_jchar('������'),
		-font => "TKFN",
	)->pack(-side => 'left');

	$self->{entry_dim_number} = $fnd->Entry(
		-font       => "TKFN",
		-width      => 2,
		-background => 'white',
	)->pack(-side => 'left', -padx => 2);
	
	$self->{entry_dim_number}->bind("<Key-Return>",sub{$self->calc;});
	$self->config_entry_focusin($self->{entry_dim_number});
	if ( $self->{command_f} =~ /k=([123])[\), ]/ ){
		$self->{entry_dim_number}->insert(0,$1);
	} else {
		$self->{entry_dim_number}->insert(0,'2');
	}

	$fnd->Label(
		-text => $self->gui_jchar('��1����3�ޤǤ��ϰϤǻ����'),
		-font => "TKFN",
	)->pack(-side => 'left');

	return $self;
}

sub calc{
	my $self = shift;

	my $r_command = '';
	if ($self->{command_f} =~ /\A(.+)# END: DATA.+/s){
		$r_command = $1;
		#print "chk: $r_command\n";
		$r_command = Jcode->new($r_command)->euc
			if $::config_obj->os eq 'win32';
	} else {
		gui_errormsg->open(
			type => 'msg',
			msg  => 'Ĵ���˼��Ԥ��ޤ��ޤ�����',
		);
		print "$self->{command_f}\n";
		$self->close;
		return 0;
	}

	$r_command .= "# END: DATA\n";

	my $fontsize = $self->gui_jg( $self->{entry_font_size}->get );
	$fontsize /= 100;

	my $wait_window = gui_wait->start;
	&gui_window::word_mds::make_plot(
		font_size      => $fontsize,
		plot_size      => $self->gui_jg( $self->{entry_plot_size}->get ),
		method         => $self->gui_jg( $self->{method_opt}  ),
		method_dist    => $self->gui_jg( $self->{method_dist} ),
		r_command      => $r_command,
		plotwin_name   => 'cod_mds',
		dim_number     => $self->gui_jg( $self->{entry_dim_number}->get ),
	);
	$wait_window->end(no_dialog => 1);
	$self->close;

}

sub win_title{
	return '�����ǥ��󥰡�¿��������ˡ��Ĵ��';
}

sub win_name{
	return 'w_cod_mds_plot_opt';
}

1;