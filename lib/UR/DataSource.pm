package UR::DataSource;
use strict;
use warnings;

require UR;
our $VERSION = "0.27"; # UR $VERSION;
use Sys::Hostname;

*namespace = \&get_namespace;

UR::Object::Type->define(
    class_name => 'UR::DataSource',
    is_abstract => 1,
    doc => 'A logical database, independent of prod/dev/testing considerations or login details.',
    has => [
        namespace => { calculate_from => ['id'] },
    ],
);

our @CARP_NOT = qw(UR::Context);

sub define { shift->__define__(@_) }

sub get_namespace {
    my $class = shift->class;
    return substr($class,0,index($class,"::DataSource"));
}

sub get_name {
    my $class = shift->class;
    return lc(substr($class,index($class,"::DataSource")+14));
}

# Basic, dumb data sources do not support joins within a single
# query.  Instead the Context logic can perform a cross datasource
# join within irs own code
sub does_support_joins { 0; }

our $use_dummy_autogenerated_ids;
*use_dummy_autogenerated_ids = \$ENV{UR_USE_DUMMY_AUTOGENERATED_IDS};
sub use_dummy_autogenerated_ids {
    # This allows the saved SQL from sync database to be comparable across executions.
    # It also 
    my $class = shift;
    if (@_) {
        ($use_dummy_autogenerated_ids) = @_;
    }
    $use_dummy_autogenerated_ids ||= 0;  # Replace undef with 0
    return $use_dummy_autogenerated_ids;
}

our $last_dummy_autogenerated_id;
sub next_dummy_autogenerated_id {   
    unless($last_dummy_autogenerated_id) {
        my $hostname = hostname();
        $hostname =~ /(\d+)/;
        my $id = $1 ? $1 : 1;
        $last_dummy_autogenerated_id = ($id * -10_000_000) - ($$ * 1_000);
    }

    #limit id to fit within 11 characters
    ($last_dummy_autogenerated_id) = $last_dummy_autogenerated_id =~ m/(-\d{1,10})/;

    return --$last_dummy_autogenerated_id;
}

sub autogenerate_new_object_id_for_class_name_and_rule {
    my $ds = shift;

    if (ref $ds) {
        $ds = ref($ds) . " ID " . $ds->id;
    }

    # Maybe we could use next_dummy_autogenerated_id instead?
    die "Data source $ds did not implement autogenerate_new_object_id_for_class_name_and_rule()";
}

# UR::Context needs to know if a data source supports savepoints
sub can_savepoint {
    my $class = ref($_[0]);
    die "Class $class didn't supply can_savepoint()";
}

sub set_savepoint {
    my $class = ref($_[0]);
    die "Class $class didn't supply set_savepoint, but can_savepoint is true";
}

sub rollback_to_savepoint {
    my $class = ref($_[0]);
    die "Class $class didn't supply rollback_to_savepoint, but can_savepoint is true";
}


sub _get_class_data_for_loading {
    my ($self, $class_meta) = @_;
    my $class_data = $class_meta->{loading_data_cache};
    unless ($class_data) {
        $class_data = $self->_generate_class_data_for_loading($class_meta);
    }
    return $class_data;
}
    
sub _get_template_data_for_loading {
    my ($self, $rule_template) = @_;
    my $template_data = $rule_template->{loading_data_cache};
    unless ($template_data) {
        $template_data = 
            $rule_template->{loading_data_cache} =
                $self->_generate_template_data_for_loading($rule_template,@_);
    } 
    return $template_data;
}


# Child classes can override this to return a different datasource
# depending on the rule passed in
sub resolve_data_sources_for_rule {
    return $_[0];
}
    
sub _generate_class_data_for_loading {
    my ($self, $class_meta) = @_;

    my $class_name = $class_meta->class_name;
    my $ghost_class = $class_name->ghost_class;

    my @all_id_property_names = $class_meta->all_id_property_names();
    my @id_properties = $class_meta->id_property_names;    
    my $id_property_sorter = $class_meta->id_property_sorter;    
    my @class_hierarchy = ($class_meta->class_name,$class_meta->ancestry_class_names);

    my @parent_class_objects = $class_meta->ancestry_class_metas;
    my $sub_classification_method_name;
    my ($sub_classification_meta_class_name, $subclassify_by);
    
    my @all_properties;
    my $first_table_name;
    for my $co ( $class_meta, @parent_class_objects ) {
        my $table_name = $co->table_name;
        
        $first_table_name ||= $table_name;
        $sub_classification_method_name ||= $co->sub_classification_method_name;
        $sub_classification_meta_class_name ||= $co->sub_classification_meta_class_name;
        $subclassify_by   ||= $co->subclassify_by;
        
        push @all_properties, 
            map { [$co, $_, $table_name, 0] }
            sort { $a->property_name cmp $b->property_name }
            UR::Object::Property->get( type_name => $co->type_name );
    }

    my $sub_typing_property = $class_meta->subclassify_by;

    my $class_table_name = $class_meta->table_name;
    #my @type_names_under_class_with_no_table;
    #unless($class_table_name) {
    #    my @type_names_under_class_with_no_table = ($class_meta->type_name, $class_meta->all_derived_type_names);
    #}

    my $class_data = {
        class_name                          => $class_name,
        ghost_class                         => $class_name->ghost_class,
        
        parent_class_objects                => [$class_meta->ancestry_class_metas], ##
        sub_classification_method_name      => $sub_classification_method_name,
        sub_classification_meta_class_name  => $sub_classification_meta_class_name,
        subclassify_by    => $subclassify_by,
        
        all_properties                      => \@all_properties,
        all_id_property_names               => [$class_meta->all_id_property_names()],
        id_properties                       => [$class_meta->id_property_names],    
        id_property_sorter                  => $class_meta->id_property_sorter,    
        
        sub_typing_property                 => $sub_typing_property,
        
        # these seem like they go in the RDBMS subclass, but for now the 
        # "table" concept is stretched to mean any valid structure identifier 
        # within the datasource.
        first_table_name                    => $first_table_name,
        #type_names_under_class_with_no_table => \@type_names_under_class_with_no_table,
        class_table_name                    => $class_table_name,
    };
    
    return $class_data;
}

sub _generate_template_data_for_loading {
    # TODO: most of this only applies to the RDBMS subclass,
    # but some applies to any datasource.  It doesn't hurt to have the RDBMS stuff
    # here and ignored, but it's not placed correctly.
    
    my ($self, $rule_template) = @_;
        
    # class-based values
    
    my $class_name = $rule_template->subject_class_name;
    my $class_meta = $class_name->__meta__;
    my $class_data = $self->_get_class_data_for_loading($class_meta);       

    my @parent_class_objects                = @{ $class_data->{parent_class_objects} };
    my @all_properties                      = @{ $class_data->{all_properties} };
#    my $first_table_name                    = $class_data->{first_table_name};
    my $sub_classification_meta_class_name  = $class_data->{sub_classification_meta_class_name};
    my $subclassify_by    = $class_data->{subclassify_by};
    
    my @all_id_property_names               = @{ $class_data->{all_id_property_names} };
    my @id_properties                       = @{ $class_data->{id_properties} };   
    my $id_property_sorter                  = $class_data->{id_property_sorter};    
    
#    my $order_by_clause                     = $class_data->{order_by_clause};
    
#    my @lob_column_names                    = @{ $class_data->{lob_column_names} };
#    my @lob_column_positions                = @{ $class_data->{lob_column_positions} };
    
#    my $query_config                        = $class_data->{query_config}; 
#    my $post_process_results_callback       = $class_data->{post_process_results_callback};

    my $sub_typing_property                 = $class_data->{sub_typing_property};
    my $class_table_name                    = $class_data->{class_table_name};
    #my @type_names_under_class_with_no_table= @{ $class_data->{type_names_under_class_with_no_table} };
    
    # individual query/boolexpr based
    
    my $recursion_desc = $rule_template->recursion_desc;
    my $recurse_property_on_this_row;
    my $recurse_property_referencing_other_rows;
    if ($recursion_desc) {
        ($recurse_property_on_this_row,$recurse_property_referencing_other_rows) = @$recursion_desc;        
    }        
    
    # _usually_ items freshly loaded from the DB don't need to be evaluated through the rule
    # because the SQL gets constructed in such a way that all the items returned would pass anyway.
    # But in certain cases (a delegated property trying to match a non-object value (which is a bug
    # in the caller's code from one point of view) or with calculated non-sql properties, then the
    # sql will return a superset of the items we're actually asking for, and the loader needs to
    # validate them through the rule
    my $needs_further_boolexpr_evaluation_after_loading; 
    
    # Does fulfilling this request involve querying more than one data source?
    my $is_join_across_data_source;

    my @sql_params;
    my @filter_specs;         
    my @property_names_in_resultset_order;
    my $object_num = 0; # 0-based, usually zero unless there are joins
    
    my @filters = $rule_template->_property_names;
    my %filters =     
        map { $_ => 0 }
        grep { substr($_,0,1) ne '-' }
        @filters;
    
    unless (@all_id_property_names == 1 && $all_id_property_names[0] eq "id") {
        delete $filters{'id'};
    }
    
    my (
        @sql_joins,
        @sql_filters, 
        $prev_table_name, 
        $prev_id_column_name, 
        $eav_class, 
        @eav_properties,
        $eav_cnt, 
        %pcnt, 
        $pk_used,
        @delegated_properties,    
        %outer_joins,
    );

    for my $co ( $class_meta, @parent_class_objects ) {
#        my $table_name = $co->table_name;
#        next unless $table_name;

#        $first_table_name ||= $table_name;

        my $type_name  = $co->type_name;
        my $class_name = $co->class_name;
        
        last if ( ($class_name eq 'UR::Object') or (not $class_name->isa("UR::Object")) );
        
        my @id_property_objects = $co->direct_id_property_metas;
        
        if (@id_property_objects == 0) {
            @id_property_objects = $co->property_meta_for_name("id");
            if (@id_property_objects == 0) {
                $DB::single = 1;
                Carp::confess("Couldn't determine ID properties for $class_name\n");
            }
        }
        
        my %id_properties = map { $_->property_name => 1 } @id_property_objects;
        my @id_column_names =
            map { $_->column_name }
            @id_property_objects;
        
#        if ($prev_table_name)
#        {
#            # die "Database-level inheritance cannot be used with multi-value-id classes ($class_name)!" if @id_property_objects > 1;
#            Carp::confess("No table for class $co->{class_name}") unless $table_name; 
#            push @sql_joins,
#                $table_name =>
#                    {
#                        $id_property_objects[0]->column_name => { 
#                            link_table_name => $prev_table_name, 
#                            link_column_name => $prev_id_column_name 
#                        }
#                    };
#            delete $filters{ $id_property_objects[0]->property_name } if $pk_used;
#        }

        for my $property_name (sort keys %filters)
        {                
            my $property = UR::Object::Property->get(type_name => $type_name, property_name => $property_name);                
            next unless $property;
            
            my $operator       = $rule_template->operator_for($property_name);
            my $value_position = $rule_template->value_position_for_property_name($property_name);
            
            delete $filters{$property_name};
            $pk_used = 1 if $id_properties{ $property_name };
            
#            if ($property->can("expr_sql")) {
#                my $expr_sql = $property->expr_sql;
#                push @sql_filters, 
#                    $table_name => 
#                        { 
#                            # cheap hack of putting a whitespace differentiates 
#                            # from a regular column below
#                            " " . $expr_sql => { operator => $operator, value_position => $value_position }
#                        };
#                next;
#            }
            
            if ($property->is_legacy_eav) {
                die "Old GSC EAV can be handled with a via/to/where/is_mutable=1";
            }
            elsif ($property->is_transient) {
                die "Query by transient property $property_name on $class_name cannot be done!";
            }
            elsif ($property->is_delegated) {
                push @delegated_properties, $property;
            }
            elsif ($property->is_calculated) {
                $needs_further_boolexpr_evaluation_after_loading = 1;
            }
            else {
                # normal column: filter on it
                push @sql_filters, 
                    $class_name => 
                        { 
                            $property_name => { operator => $operator, value_position => $value_position }
                        };
            }
        }
        
#        $prev_table_name = $table_name;
        $prev_id_column_name = $id_property_objects[0]->column_name;
        
    } # end of inheritance loop
        
    if ( my @errors = keys(%filters) ) { 
        my $class_name = $class_meta->class_name;
        $self->error_message('Unknown param(s) (' . join(',',@errors) . ") used to generate SQL for $class_name!");
        Carp::confess();
    }

    my $last_class_name = $class_name;
    my $last_class_object = $class_meta;        
#    my $last_table_alias = $last_class_object->table_name; 
    my $alias_num = 1;

    my %joins_done;
    my @joins_done;
    my $joins_across_data_sources;

    DELEGATED_PROPERTY:
    for my $delegated_property (@delegated_properties) {
        my $last_alias_for_this_chain;
    
        my $property_name = $delegated_property->property_name;
        my @joins = $delegated_property->_get_joins;
        my $relationship_name = $delegated_property->via;
        unless ($relationship_name) {
           $relationship_name = $property_name;
           $needs_further_boolexpr_evaluation_after_loading = 1;
        }

        my $delegate_class_meta = $delegated_property->class_meta;
        my $via_accessor_meta = $delegate_class_meta->property_meta_for_name($relationship_name);
        my $final_accessor = $delegated_property->to;            
        my $final_accessor_meta = $via_accessor_meta->data_type->__meta__->property_meta_for_name($final_accessor);
        unless ($final_accessor_meta) {
            Carp::croak("No property '$final_accessor' on class " . $via_accessor_meta->data_type .
                          " while resolving property $property_name on class $class_name");
        }
        while($final_accessor_meta->is_delegated) {
            $final_accessor_meta = $final_accessor_meta->to_property_meta();
            unless ($final_accessor_meta) {
                Carp::croak("No property '$final_accessor' on class " . $via_accessor_meta->data_type .
                              " while resolving property $property_name on class $class_name");
            }
        }
        $final_accessor = $final_accessor_meta->property_name;

        #print "$property_name needs join "
        #    . " via $relationship_name "
        #    . " to $final_accessor"
        #    . " using joins ";
        
        #my $final_table_name_with_alias = $first_table_name; 
        
        for my $join (@joins) {
            #print "\tjoin $join\n";

            my $source_class_name = $join->{source_class};
            my $source_class_object = $join->{'source_class_meta'} || $source_class_name->__meta__;

            my $foreign_class_name = $join->{foreign_class};
            my $foreign_class_object = $join->{'foreign_class_meta'} || $foreign_class_name->__meta__;
            my($foreign_data_source) = $UR::Context::current->resolve_data_sources_for_class_meta_and_rule($foreign_class_object, $rule_template);
            if (! $foreign_data_source) {
                $needs_further_boolexpr_evaluation_after_loading = 1;
                next DELEGATED_PROPERTY;

            } elsif ($foreign_data_source ne $self or
                    ! $self->does_support_joins or
                    ! $foreign_data_source->does_support_joins
                )
            {
                push(@{$joins_across_data_sources->{$foreign_data_source->id}}, $delegated_property);
                next DELEGATED_PROPERTY;
            }

            my @source_property_names = @{ $join->{source_property_names} };

            my @source_table_and_column_names = 
                map {
                    my $p = $source_class_object->property_meta_for_name($_);
                    unless ($p) {
                        Carp::confess("No property $_ for class $source_class_object->{class_name}\n");
                    }
                    [$p->class_name->__meta__->class_name, $p->property_name];
                }
                @source_property_names;

            #print "source column names are @source_table_and_column_names for $property_name\n";            

            my $foreign_table_name = $foreign_class_name;

            unless ($foreign_table_name) {
                # If we can't make the join because there is no datasource representation
                # for this class, we're done following the joins for this property
                # and will NOT try to filter on it at the datasource level
                $needs_further_boolexpr_evaluation_after_loading = 1;
                next DELEGATED_PROPERTY;
            }

            my @foreign_property_names = @{ $join->{foreign_property_names} };
            my @foreign_property_meta = 
                map {
                    $foreign_class_object->property_meta_for_name($_)
                }
                @foreign_property_names;
            
            my @foreign_column_names = 
                map {
                    # TODO: encapsulate
                    $_->is_calculated ? (defined($_->calculate_sql) ? ($_->calculate_sql) : () ) : ($_->property_name)
                }
                @foreign_property_meta;
                
            unless (@foreign_column_names) {
                # all calculated properties: don't try to join any further
                last;
            }
            unless (@foreign_column_names == @foreign_property_meta) {
                # some calculated properties, be sure to re-check for a match after loading the object
                $needs_further_boolexpr_evaluation_after_loading = 1;
            }
            
            my $alias = $joins_done{$join->{id}};
            unless ($alias) {            
                $alias = "${relationship_name}_${alias_num}";
                $alias_num++;
                $object_num++;
                
                push @sql_joins,
                    "$foreign_table_name $alias" =>
                        {
                            map {
                                $foreign_property_names[$_] => { 
                                    link_table_name     => $last_alias_for_this_chain || $source_table_and_column_names[$_][0],
                                    link_column_name    => $source_table_and_column_names[$_][1] 
                                }
                            }
                            (0..$#foreign_property_names)
                        };
                    
                # Add all of the columns in the join table to the return list.                
                push @all_properties, 
                    map { [$foreign_class_object, $_, $alias, $object_num] }
                    sort { $a->property_name cmp $b->property_name }
                    grep { defined($_->column_name) && $_->column_name ne '' }
                    UR::Object::Property->get( type_name => $foreign_class_object->type_name );
              
                $joins_done{$join->{id}} = $alias;
                push @joins_done, $join;
                
            }
            
            # Set these for after all of the joins are done
            $last_class_name = $foreign_class_name;
            $last_class_object = $foreign_class_object;
            $last_alias_for_this_chain = $alias;
            #$last_table_alias = $alias;
            #$final_table_name_with_alias = "$foreign_table_name $alias";
            
        } # next join

        unless ($delegated_property->via) {
            next;
        }

        my $final_accessor_property_meta = $last_class_object->property_meta_for_name($final_accessor);
        my $sql_lvalue;
        if ($final_accessor_property_meta->is_calculated) {
            $sql_lvalue = $final_accessor_property_meta->calculate_sql;
            unless (defined($sql_lvalue)) {
                    $needs_further_boolexpr_evaluation_after_loading = 1;
                next;
            }
        }
        else {
            $sql_lvalue = $final_accessor_property_meta->column_name;
            unless (defined($sql_lvalue)) {
                Carp::confess("No column name set for non-delegated/calculated property $property_name of $class_name");
            }
        }

        my $operator       = $rule_template->operator_for($property_name);
        my $value_position = $rule_template->value_position_for_property_name($property_name);                
        #push @sql_filters, 
        #    $final_table_name_with_alias => { 
        #        $sql_lvalue => { operator => $operator, value_position => $value_position } 
        #    };
    } # next delegated property
    
    for my $property_meta_array (@all_properties) {
        push @property_names_in_resultset_order, $property_meta_array->[1]->property_name; 
    }
    
    my $rule_template_without_recursion_desc = ($recursion_desc ? $rule_template->remove_filter('-recurse') : $rule_template);
    
    my $rule_template_specifies_value_for_subtype;
    if ($sub_typing_property) {
        $rule_template_specifies_value_for_subtype = $rule_template->specifies_value_for($sub_typing_property)
    }

    my $per_object_in_resultset_loading_detail = $self->_generate_loading_templates_arrayref(\@all_properties);

    my $template_data = $rule_template->{loading_data_cache} = {
        %$class_data,
        
        properties_for_params                       => \@all_properties,  
        property_names_in_resultset_order           => \@property_names_in_resultset_order,
        joins                                       => \@sql_joins,
        
        rule_template_id                            => $rule_template->id,
        rule_template_without_recursion_desc        => $rule_template_without_recursion_desc,
        rule_template_id_without_recursion_desc     => $rule_template_without_recursion_desc->id,
        rule_matches_all                            => $rule_template->matches_all,
        rule_specifies_id                           => ($rule_template->specifies_value_for('id') || undef),
        rule_template_is_id_only                    => $rule_template->is_id_only,
        rule_template_specifies_value_for_subtype   => $rule_template_specifies_value_for_subtype,
        
        recursion_desc                              => $rule_template->recursion_desc,
        recurse_property_on_this_row                => $recurse_property_on_this_row,
        recurse_property_referencing_other_rows     => $recurse_property_referencing_other_rows,
        
        loading_templates                           => $per_object_in_resultset_loading_detail,

        joins_across_data_sources                   => $joins_across_data_sources,
    };

        
    return $template_data;
}

sub _generate_loading_templates_arrayref {
    # Each entry represents a table alias in the query.
    # This accounts for different tables, or multiple occurrances 
    # of the same table in a join, by grouping by alias instead of
    # table.
    
    my $class = shift;
    my $sql_cols = shift;

    use strict;
    use warnings;

    my %templates;
    my $pos = 0;
    my @templates;
    for my $col_data (@$sql_cols) {
        my ($class_obj, $prop, $table_alias, $object_num, $class_name) = @$col_data;
        unless (defined $object_num) {
            die "No object num for loading template data?!";
        }
        my $template = $templates[$object_num];
        unless ($template) {
            $template = {
                object_num => $object_num,
                table_alias => $table_alias,
                data_class_name => $class_obj->class_name,
                final_class_name => $class_name || $class_obj->class_name,
                property_names => [],                    
                column_positions => [],                    
                id_property_names => undef,
                id_column_positions => [],
                id_resolver => undef, # subref
            };
            $templates[$object_num] = $template;
        }
        push @{ $template->{property_names} }, $prop->property_name;
        push @{ $template->{column_positions} }, $pos;
        $pos++;
    }
    
    # Post-process the template objects a bit to get the exact id positions.
    for my $template (@templates) {
        next unless $template;  # This join may have resulted in no template?!
        my @id_property_names;
        unless (defined $template->{data_class_name}) {
            $DB::single=1;
            print "No data class name in template: ", Data::Dumper::Dumper($template); 
        }
        for my $id_class_name ($template->{data_class_name}, $template->{data_class_name}->inheritance) {
            my $id_class_obj = UR::Object::Type->get(class_name => $id_class_name);
            last if @id_property_names = $id_class_obj->id_property_names;
        }
        $template->{id_property_names} = \@id_property_names;
        
        my @id_column_positions;
        for my $id_property_name (@id_property_names) {
            for my $n (0..$#{ $template->{property_names} }) {
                if ($template->{property_names}[$n] eq $id_property_name) {
                    push @id_column_positions, $template->{column_positions}[$n];
                    last;
                }
            }
        }
        $template->{id_column_positions} = \@id_column_positions;            
        
        if (@id_column_positions == 1) {
            $template->{id_resolver} = sub {
                return $_[0][$id_column_positions[0]];
            }
        }
        elsif (@id_column_positions > 1) {
            my $class_name = $template->{data_class_name};
            $template->{id_resolver} = sub {
                my $self = shift;
                return $class_name->__meta__->resolve_composite_id_from_ordered_values(@$self[@id_column_positions]);
            }                    
        }
        else {
            die "No id column positions for template " . Data::Dumper::Dumper($template);
        }             
    }        

    return \@templates;        
}

sub create_iterator_closure_for_rule_template_and_values {
    my ($self, $rule_template, @values) = @_;
    my $rule = $rule_template->get_rule_for_values(@values);
    return $self->create_iterator_closure_for_rule($rule);
}

sub _reclassify_object_loading_info_for_new_class {
    my $self = shift;
    my $loading_info = shift;
    my $new_class = shift;

    my $new_info;
    %$new_info = %$loading_info;

    foreach my $template_id (keys %$loading_info) {

        my $target_class_rules = $loading_info->{$template_id};
        foreach my $rule_id (keys %$target_class_rules) {
            my $pos = index($rule_id,'/');
            $new_info->{$template_id}->{$new_class . "/" . substr($rule_id,$pos+1)} = 1;
        }
    }

    return $new_info;
}

sub _get_object_loading_info {
    my $self = shift;
    my $obj  = shift;
    my %param_load_hash;
    if ($obj->{'__load'}) {
        while( my($template_id, $rules) = each %{ $obj->{'__load'} } ) {
            foreach my $rule_id ( keys %$rules ) {
                $param_load_hash{$template_id}->{$rule_id} = $UR::Context::all_params_loaded->{$template_id}->{$rule_id};
            }
        }
    }
    return \%param_load_hash;
}


sub _add_object_loading_info {
    my $self = shift;
    my $obj = shift;
    my $param_load_hash = shift;

    while( my($template_id, $rules) = each %$param_load_hash) {
        foreach my $rule_id ( keys %$rules ) {
            $obj->{'__load'}->{$template_id}->{$rule_id} = $rules->{$rule_id};
        }
    }
}


# same as add_object_loading_info, but manipulates the data in $UR::Context::all_params_loaded
sub _record_that_loading_has_occurred {
    my $self = shift;
    my $param_load_hash = shift;

    while( my($template_id, $rules) = each %$param_load_hash) {
        foreach my $rule_id ( keys %$rules ) {
            $UR::Context::all_params_loaded->{$template_id}->{$rule_id} ||=
                $rules->{$rule_id};
        }
    }
}

sub _first_class_in_inheritance_with_a_table {
    # This is called once per subclass and cached in the subclass from then on.
    my $self = shift;
    my $class = shift;
    $class = ref($class) if ref($class);


    unless ($class) {
        $DB::single = 1;
        Carp::confess("No class?");
    }
    my $class_object = $class->__meta__;
    my $found = "";
    for ($class_object, $class_object->ancestry_class_metas)
    {                
        if ($_->table_name)
        {
            $found = $_->class_name;
            last;
        }
    }
    #eval qq/
    #    package $class;
    #    sub _first_class_in_inheritance_with_a_table { 
    #        return '$found' if \$_[0] eq '$class';
    #        shift->SUPER::_first_class_in_inheritance_with_a_table(\@_);
    #    }
    #/;
    #die "Error setting data in subclass: $@" if $@;
    return $found;
}

sub _class_is_safe_to_rebless_from_parent_class {
    my ($self, $class, $was_loaded_as_this_parent_class) = @_;
    my $fcwt = $self->_first_class_in_inheritance_with_a_table($class);
    die "No parent class with a table found for $class?!" unless $fcwt;
    return ($was_loaded_as_this_parent_class->isa($fcwt));
}


sub _CopyToAlternateDB {
    # This is used to copy data loaded from the primary database into
    # a secondary database.  One use is for setting up an alternate DB
    # for testing by priming it from data from the "live" DB
    #
    # This is called from inside load() when the env var UR_TEST_FILLDB
    # is set.  For now, this alternate DB is always an SQLIte DB, and the
    # value of the env var is the base name of the file used as its storage.

    my($self,$load_class_name,$orig_dbh,$data) = @_;

    our %ALTERNATE_DB;
    my $dbname = $orig_dbh->{'Name'};

    my $dbh;
    if ($ALTERNATE_DB{$dbname}->{'dbh'}) {
        $dbh = $ALTERNATE_DB{$dbname}->{'dbh'};
    } else {
        my $filename = sprintf("%s.%s.sqlite", $ENV{'UR_TEST_FILLDB'}, $dbname);

        # FIXME - The right way to do this is to create a new UR::DataSource::SQLite object instead of making a DBI object directly
        unless ($dbh = $ALTERNATE_DB{$dbname}->{'dbh'} = DBI->connect("dbi:SQLite:dbname=$filename","","")) {
            $self->error_message("_CopyToAlternateDB: Can't DBI::connect() for filename $filename" . $DBI::errstr);
            return;
        }
        $dbh->{'AutoCommit'} = 0;
    }

    # Find out what tables this query will require
    my @isa = ($load_class_name);
    my(%tables,%class_tables);
    while (@isa) {
        my $class = shift @isa;
        next if $class_tables{$class};

        my $class_obj = $class->__meta__;
        next unless $class_obj;

        my $table_name = $class_obj->table_name;
        next unless $table_name;
        $class_tables{$class} = $table_name;

        foreach my $col ( $class_obj->direct_column_names ) {
            # FIXME Why are some of the returned column_names undef?
            next unless defined($col); # && defined($data->{$col});
            $tables{$table_name}->{$col} = $data->{$col} 
        }
        {   no strict 'refs';
            my @parents = @{$class . '::ISA'};
            push @isa, @parents;
        }
    }
    
    # For each parent class with a table, tell it to create itself
    foreach my $class ( keys %class_tables ) {
        next if (! $class_tables{$class} || $ALTERNATE_DB{$dbname}->{'tables'}->{$class_tables{$class}}++);

        my $class_obj = $class->__meta__();
        $class_obj->mk_table($dbh);
        #unless ($class_obj->mk_table($dbh)) {
        #    $dbh->rollback();
        #    return undef;
        #}
    }

    # Insert the data into the alternate DB
    foreach my $table_name ( keys %tables ) {
        my $sql = "INSERT INTO $table_name ";

        my $num_values = (values %{$tables{$table_name}});
        $sql .= "(" . join(',',keys %{$tables{$table_name}}) . ") VALUES (" . join(',', map {'?'} (1 .. $num_values)) . ")";
        my $sth = $dbh->prepare_cached($sql);
        unless ($sth) {
            $self->error_message("Error in prepare to alternate DB: $DBI::errstr\nSQL: $sql");
            $dbh->rollback();
            return undef;
        }

        unless ( $sth->execute(values %{$tables{$table_name}}) ) {
            $self->warning_message("Can't insert into $table_name in alternate DB: ".$DBI::errstr."\nSQL: $sql\nPARAMS: ".
                                   join(',',values %{$tables{$table_name}}));

            # We might just be inserting data that's already there...
            # This is the error message sqlite returns
            if ($DBI::errstr !~ m/column (\w+) is not unique/i) {
                $dbh->rollback();
                return undef;
            }
        }
    }

    $dbh->commit();
    
    1;
}

sub _get_current_entities {
    my $self = shift;
    my @class_meta = UR::Object::Type->is_loaded(
        data_source_id => $self->id
    );
    my @objects;
    for my $class_meta (@class_meta) {
        next unless $class_meta->generated();  # Ungenerated classes won't have any instances
        my $class_name = $class_meta->class_name;
        push @objects, $UR::Context::current->all_objects_loaded($class_name);
    }
    return @objects;
}


sub _prepare_for_lob { };

sub _set_specified_objects_saved_uncommitted {
    my ($self,$objects_arrayref) = @_;
    # Sets an objects as though the has been saved but tha changes have not been committed.
    # This is called automatically by _sync_databases.

    my %objects_by_class;
    my $class_name;
    for my $object (@$objects_arrayref) {
        $class_name = ref($object);
        $objects_by_class{$class_name} ||= [];
        push @{ $objects_by_class{$class_name} }, $object;
    }

    for my $class_name (sort keys %objects_by_class) {
        my $class_object = $class_name->__meta__;
        my @property_names =
            map { $_->property_name }
            grep { $_->column_name }
            $class_object->all_property_metas;

        for my $object (@{ $objects_by_class{$class_name} }) {
            $object->{db_saved_uncommitted} ||= {};
            my $db_saved_uncommitted = $object->{db_saved_uncommitted};
            for my $property ( @property_names ) {
                $db_saved_uncommitted->{$property} = $object->$property;
            }
        }
    }
    return 1;
}

sub _set_all_objects_saved_committed {
    # called by UR::DBI on commit
    my $self = shift;
    my @objects = $self->_get_current_entities;
    for my $obj (@objects)  {
        unless ($self->_set_object_saved_committed($obj)) {
            die "An error occurred setting " . $obj->__display_name__
             . " to match the committed database state.  Exiting...";
        }
    }
    return scalar(@objects) || "0 but true";
}

sub _set_object_saved_committed {
    # called by the above, and some test cases
    my ($self, $object) = @_;
    if ($object->{db_saved_uncommitted}) {
        if ($object->isa("UR::Object::Ghost")) {
            $object->__signal_change__("commit");
            $UR::Context::current->_abandon_object($object);
        }
        else {
            %{ $object->{db_committed} } = (
                ($object->{db_committed} ? %{ $object->{db_committed} } : ()),
                %{ $object->{db_saved_uncommitted} }
            );
            delete $object->{db_saved_uncommitted};
            $object->__signal_change__("commit");
        }
    }
    return $object;
}

sub _set_all_objects_saved_rolled_back {
    # called by UR::DBI on commit
    my $self = shift;
    my @objects = $self->_get_current_entities;
    for my $obj (@objects)  {
        unless ($self->_set_object_saved_rolled_back($obj)) {
            die "An error occurred setting " . $obj->__display_name__
             . " to match the rolled-back database state.  Exiting...";
        }
    }
}


sub _set_object_saved_rolled_back {
    # called by the above, and some test cases
    my ($self,$object) = @_;
    delete $object->{db_saved_uncommitted};
    return $object;
}


# These are part of the basic DataSource API.  Subclasses will want to override these

sub _sync_database {
    my $class = shift;
    my %args = @_;
    $class = ref($class) || $class;

    $class->warning_message("Data source $class does not support saving objects to storage.  " . 
                            scalar(@{$args{'changed_objects'}}) . " objects will not be saved");
    return 1;
}

sub commit {
    my $class = shift;
    my %args = @_;
    $class = ref($class) || $class;

    #$class->warning_message("commit() ignored for data source $class");
    return 1;
}

sub rollback {
    my $class = shift;
    my %args = @_;
    $class = ref($class) || $class;

    $class->warning_message("rollback() ignored for data source $class");
    return 1;
}

# basic, dumb datasources do not have a handle
sub get_default_handle {
    return;
}

# When the class initializer is create property objects, it will
# auto-fill-in column_name if the class definition has a table_name.
# File-based data sources do not have tables (and so classes using them
# do not have table_names), but the properties still need column_names
# so loading works properly.
# For now, only UR::DataSource::File and ::FileMux set this.
# FIXME this method's existence is ugly.  Find a better way to fill in
# column_name for those properties, or fix the data sources to not
# require column_names to be set by the initializer
sub initializer_should_create_column_name_for_class_properties {
    return 0;
}


# Subclasses should override this.
# It's called by the class initializer when the data_source property in a class
# definition contains a hashref with an 'is' key.  The method should accept this
# hashref, create a data_source instance (if appropriate) and return the class_name
# of this new datasource.
sub create_from_inline_class_data {
    my ($class,$class_data,$ds_data) = @_;
    my %ds_data = %$ds_data;
    my $ds_class_name = delete $ds_data{is};
    unless (my $ds_class_meta = UR::Object::Type->get($ds_class_name)) {
        die "No class $ds_class_name found!";
    }
    my $ds = $ds_class_name->__define__(%ds_data);
    unless ($ds) {
        die "Failed to construct $ds_class_name: " . $ds_class_name->error_message();
    }
    return $ds;
}


1;
