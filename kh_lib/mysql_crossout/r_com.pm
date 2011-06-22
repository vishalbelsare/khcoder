package mysql_crossout::r_com;
use base qw(mysql_crossout);
use strict;

sub run{
	my $self = shift;
	
	use Benchmark;
	
	# ���Ф��μ���
	$self->{midashi} = mysql_getheader->get_selected(tani => $self->{tani2});

	$self->make_list;

	$self->{tani} = $self->{tani2};

	my $t0 = new Benchmark;
	$self->out2;
	#$self->finish;
	
	my $t1 = new Benchmark;
	print "\n",timestr(timediff($t1,$t0)),"\n";
	
	print "Data matrix for R: $self->{num_w} words x $self->{num_r} docs\n";
	
	return $self->{r_command};
}

#----------------#
#   �ǡ�������   #

sub out2{                               # length�����򤹤�
	my $self = shift;
	
	$self->{r_command} = "d <- NULL\n";
	my $row_names = '';
	
	my $length = 'doc_length_mtr <- matrix( c( ';
	
	my $num_r = 0;
	
	# �������Ƥκ���
	my $id = 1;
	my $last = 1;
	my %current = ();
	while (1){
		my $sth = mysql_exec->select(
			$self->sql2($id, $id + 100),
			1
		)->hundle;
		$id += 100;
		unless ($sth->rows > 0){
			last;
		}
		
		while (my $i = $sth->fetch){
			if ($last != $i->[0]){
				# �񤭽Ф�
				my $temp = "$last,";
				if ($self->{midashi}){
					$self->{midashi}->[$last - 1] =~ s/"/ /g;
					$row_names .= '"'.$self->{midashi}->[$last - 1].'",';
				}
				foreach my $h (@{$self->{wList}} ){
					if ($current{$h}){
						$temp .= "$current{$h},";
					} else {
						$temp .= "0,";
					}
				}
				chop $temp;
				$self->{r_command} .= "d <- rbind(d, c($temp) )\n";
				$length .= "$current{length_c},$current{length_w},";
				# �����
				%current = ();
				$last = $i->[0];
				++$num_r;
			}
			
			# HTML������̵��
			if (
				!  ( $self->{use_html} )
				&& ( $i->[2] =~ /<[h|H][1-5]>|<\/[h|H][1-5]>/o )
			){
				next;
			}
			# ̤���Ѹ��̵��
			if ($i->[3]){
				next;
			}
			
			# ����
			++$current{'length_w'};
			$current{'length_c'} += (length($i->[2]) / 2);
			if ($self->{wName}{$i->[1]}){
				++$current{$i->[1]};
			}
		}
		$sth->finish;
	}
	
	# �ǽ��Ԥν���
	my $temp = "$last,";
	if ($self->{midashi}){
		$self->{midashi}->[$last - 1] =~ s/"/ /g;
		$row_names .= '"'.$self->{midashi}->[$last - 1].'",';
	}
	foreach my $h (@{$self->{wList}} ){
		if ($current{$h}){
			$temp .= "$current{$h},";
		} else {
			$temp .= "0,";
		}
	}
	chop $temp;
	$self->{r_command} .= "d <- rbind(d, c($temp) )\n";
	$length .= "$current{length_c},$current{length_w},";
	chop $row_names;
	++$num_r;
	
	# �ǡ�������
	if ($self->{rownames}){
		if ($self->{midashi}){
			$self->{r_command} .= "row.names(d) <- c($row_names)\n";
		} else {
			$self->{r_command} .= "row.names(d) <- d[,1]\n";
		}
	}

	$self->{r_command} .= "d <- d[,-1]\n";

	$self->{r_command} .= "colnames(d) <- c(";
	foreach my $i (@{$self->{wList}}){
		my $t = $self->{wName}{$i};
		$t =~ s/"/ /g;
		$self->{r_command} .= "\"$t\",";
	}
	chop $self->{r_command};
	$self->{r_command} .= ")\n";

	chop $length;
	$length .= "), ncol=2, byrow=T)\n";
	$length .= "colnames(doc_length_mtr) <- c(\"length_c\", \"length_w\")\n";
	$self->{r_command} .= $length;

	$self->{num_r} = $num_r;

	return $self;
}


#--------------------------#
#   ���Ϥ���ñ������֤�   #

sub wnum{
	my $self = shift;
	
	$self->{min_df} = 0 unless length($self->{min_df});
	
	my $sql = '';
	$sql .= "SELECT count(*)\n";
	$sql .= "FROM   genkei, hselection, df_$self->{tani}";
	if ($self->{tani2} and not $self->{tani2} eq $self->{tani}){
		$sql .= ", df_$self->{tani2}\n";
	} else {
		$sql .= "\n";
	}
	$sql .= "WHERE\n";
	$sql .= "	    genkei.khhinshi_id = hselection.khhinshi_id\n";
	$sql .= "	AND genkei.num >= $self->{min}\n";
	$sql .= "	AND genkei.nouse = 0\n";
	$sql .= "	AND genkei.id = df_$self->{tani}.genkei_id\n";
	if ($self->{tani2} and not $self->{tani2} eq $self->{tani}){
		$sql .= "	AND genkei.id = df_$self->{tani2}.genkei_id\n";
		$sql .= "	AND df_$self->{tani2}.f >= 1\n";
	}
	$sql .= "	AND df_$self->{tani}.f >= $self->{min_df}\n";
	$sql .= "	AND (\n";
	
	my $n = 0;
	foreach my $i ( @{$self->{hinshi}} ){
		if ($n){ $sql .= ' OR '; }
		$sql .= "hselection.khhinshi_id = $i\n";
		++$n;
	}
	$sql .= ")\n";
	if ($self->{max}){
		$sql .= "AND genkei.num <= $self->{max}\n";
	}
	if ($self->{max_df}){
		$sql .= "AND df_$self->{tani}.f <= $self->{max_df}\n";
	}
	#print "$sql\n";
	
	$_ = mysql_exec->select($sql,1)->hundle->fetch->[0];
	1 while s/(.*\d)(\d\d\d)/$1,$2/; # �̼���ѤΥ���ޤ�����
	return $_;
}

#--------------------------------#
#   ���Ϥ���ñ���ꥹ�ȥ��å�   #

# tani2�ˤ��ʸ������꤬��ǽ�ʽ�����

sub make_list{
	my $self = shift;
	
	# ñ��ꥹ�Ȥκ���
	my $sql = '';
	$sql .= "SELECT genkei.id, genkei.name, hselection.khhinshi_id\n";
	$sql .= "FROM   genkei, hselection, df_$self->{tani}";
	if ($self->{tani2} and not $self->{tani2} eq $self->{tani}){
		$sql .= ", df_$self->{tani2}\n";
	} else {
		$sql .= "\n";
	}
	$sql .= "WHERE\n";
	$sql .= "	    genkei.khhinshi_id = hselection.khhinshi_id\n";
	$sql .= "	AND genkei.num >= $self->{min}\n";
	$sql .= "	AND genkei.nouse = 0\n";
	if ($self->{tani2} and not $self->{tani2} eq $self->{tani}){
		$sql .= "	AND genkei.id = df_$self->{tani2}.genkei_id\n";
		$sql .= "	AND df_$self->{tani2}.f >= 1\n";
	}
	$sql .= "	AND genkei.id = df_$self->{tani}.genkei_id\n";
	$sql .= "	AND df_$self->{tani}.f >= $self->{min_df}\n";
	$sql .= "	AND (\n";

	my $n = 0;
	foreach my $i ( @{$self->{hinshi}} ){
		if ($n){ $sql .= ' OR '; }
		$sql .= "hselection.khhinshi_id = $i\n";
		++$n;
	}
	$sql .= ")\n";
	if ($self->{max}){
		$sql .= "AND genkei.num <= $self->{max}\n";
	}
	if ($self->{max_df}){
		$sql .= "AND df_$self->{tani}.f <= $self->{max_df}\n";
	}
	$sql .= "ORDER BY khhinshi_id, genkei.num DESC, genkei.name\n";
	
	my $sth = mysql_exec->select($sql, 1)->hundle;
	my (@list, %name, %hinshi);
	while (my $i = $sth->fetch) {
		push @list,        $i->[0];
		$name{$i->[0]}   = $i->[1];
		$hinshi{$i->[0]} = $i->[2];
	}
	$sth->finish;
	$self->{wList}   = \@list;
	$self->{wName}   = \%name;
	$self->{wHinshi} = \%hinshi;
	$self->{num_w} = @list;
	
	# �ʻ�ꥹ�Ȥκ���
	$sql = '';
	$sql .= "SELECT khhinshi_id, name\n";
	$sql .= "FROM   hselection\n";
	$sql .= "WHERE\n";
	$n = 0;
	foreach my $i ( @{$self->{hinshi}} ){
		if ($n){ $sql .= ' OR '; }
		$sql .= "khhinshi_id = $i\n";
		++$n;
	}
	$sth = mysql_exec->select($sql, 1)->hundle;
	while (my $i = $sth->fetch) {
		$self->{hName}{$i->[0]} = $i->[1];
		if ($i->[1] eq 'HTML����'){
			$self->{use_html} = 1;
		}
	}
	
	return $self;
}

1;