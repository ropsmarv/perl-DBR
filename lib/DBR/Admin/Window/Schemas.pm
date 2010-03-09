# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation.

package DBR::Admin::Window::Schemas;
use Moose;
extends 'DBR::Admin::Window';

has 'vis_tables'  => (is => 'rw', isa => 'Bool', default => 0);
has 'vis_fields'  => (is => 'rw', isa => 'Bool', default => 0);
has 'schemas'     => (is => 'rw');

sub BUILD {
      my $self = shift;

      my $button = $self->add( 'newschema', 'Buttonbox',
       			       -y => 0, -width => 20,
       			       -buttons   => [{ -label => '< Add New Schema >',
       						-onpress => sub {$self->add_edit_schema(add => 1)}
       					      }],
			      );
      my $listbox = $self->add( 'schemalistbox', 'Listbox',
				-y => 2, -width => 25, -vscrollbar => 1,
				-title => "Schemas", -border => 1,
				-onchange => sub {
				      my $schema_id = $_[0]->get;
				      my $schema = $self->schemas->{$schema_id} or die "Failed to look up schema";
				      $self->spawn('Tables',
						   title       => "$schema->{handle} tables",
						   schema_id   => $schema_id,
						   schema_name => $schema->{handle},
						  )
				},
				-onselchange => sub { print STDERR "Active is: " . $_[0]->get_active_value . "\n" }
			      );

      $self->update_schema_list($listbox);

      $listbox->focus();
      $listbox->onFocus(sub { $listbox->clear_selection });
      #$self->win->set_focusorder('fieldlistbox','tablelistbox','schemalistbox', 'newschema', 'close');
}

sub update_schema_list{
      my $self = shift;
      my $listbox = shift;
      $listbox->clear_selection;

      my $dbrh = $self->conf_instance->connect or die "Failed to connect";
      my $schemas = $dbrh->select( -table => 'dbr_schemas',
				   -fields => 'schema_id handle display_name',
				 ) or throw DBR::Admin::Exception( message => "failed to select from dbr_schema $!",
								   root_window => $self->win->root );

      my %map    = map { $_->{schema_id} => $_ } @$schemas;
      $self->schemas( \%map );

      my %labels = map { $_->{schema_id} => $_->{display_name} } @$schemas;

      $listbox->values( [ sort { lc($labels{$a}) cmp lc($labels{$b}) } keys %labels ]); # Curses::UI sucks
      $listbox->labels( \%labels );
}

sub list_fields{
      my $self = shift;
      my $table_id = shift;
      my $schemaname = shift;
      my $tablename  = shift;
      print STDERR "LIST FIELDS - table_id $table_id\n";

      $self->vis_fields(1);
      my $dbrh = $self->conf_instance->connect or die "Failed to connect";

      my $fields = $dbrh->select( -table => 'dbr_fields',
				  -fields => 'field_id table_id name data_type is_nullable is_signed max_value display_name is_pkey index_type trans_id',
				  -where => { table_id => ['d',$table_id] },
				) or throw DBR::Admin::Exception( message => "failed to select from dbr_fields $!",
								  root_window => $self->win->root()
								);
      my %labels = map { $_->{field_id} => $_->{name} } @$fields;

      $self->win->delete('fieldlistbox');
      my $listbox = $self->add( 'fieldlistbox', 'Listbox',
				-y => 2, -x => 52, -width => 25, -vscrollbar => 1,
				-title => "Fields", -border => 1,
				-values => [ sort { lc($labels{$a}) cmp lc($labels{$b}) } keys %labels ],
				-labels => \%labels,
				-onchange => sub {
				      my $fid = $_[0]->get;
				      $self->spawn( 'Field',
						    field_id => $fid,
						    title    => "$schemaname.$tablename." . $labels{$fid},
						    dimensions  => '50x15',
						    bordercolor => 'blue'
						  ) }
			      );

      $listbox->draw;
      $listbox->focus;
      $listbox->onBlur(sub{
			     #$self->win->focus('tablelistbox');
			     $self->win->delete('fieldlistbox') && $self->vis_fields(0);
		       });

}





1;