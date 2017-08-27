package Class::Accessor::PackedString;

# DATE
# VERSION

#IFUNBUILT
use strict 'subs', 'vars';
use warnings;
#END IFUNBUILT

sub import {
    my ($class0, $spec) = @_;
    my $caller = caller();

    my $class = $caller;

#IFUNBUILT
    no warnings 'redefine';
#END IFUNBUILT

    # generate accessors
    for my $meth (keys %{$spec->{accessors}}) {
        my $idx = $spec->{accessors}{$meth};
        my $code_str = 'sub (;$) { ';
        $code_str .= "\$_[0][$idx] = \$_[1] if \@_ > 1; ";
        $code_str .= "\$_[0][$idx]; ";
        $code_str .= "}";
        #say "D:accessor code for $meth: ", $code_str;
        *{"$class\::$meth"} = eval $code_str;
        die if $@;
    }

    # generate constructor
    {
        my $code_str;
        $code_str  = 'sub { my ($class, %args) = @_;';
        if (@{"$class\::ISA"}) {
            $code_str .= ' require '.${"$class\::ISA"}[0].';';
            $code_str .= ' my $self = '.${"$class\::ISA"}[0].'->new(map {($_=>delete $args{$_})}'.
                ' grep {'.(join " && ", map {'$_ ne \''.$_.'\''} keys %{$spec->{accessors}}).'} keys %args);';
            $code_str .= ' $self = bless $self, \''.$class.'\';';
        } else {
            $code_str .= ' my $self = bless [], $class;';
        }
        $code_str .= ' for my $key (grep {'.(join " || ", map {'$_ eq \''.$_.'\''} keys %{$spec->{accessors}}).'} keys %args) { $self->$key(delete $args{$key}) }';
        $code_str .= ' die "Unknown $class attributes in constructor: ".join(", ", sort keys %args) if keys %args;';
        $code_str .= ' $self }';

        #print "D:constructor code for class $class: ", $code_str, "\n";
        my $constructor = $spec->{constructor} || "new";
        unless (*{"$class\::$constructor"}{CODE}) {
            *{"$class\::$constructor"} = eval $code_str;
            die if $@;
        };
    }
}

1;
# ABSTRACT: Generate accessors/constructor for object that use pack()-ed string as storage backend

=for Pod::Coverage .+

=head1 SYNOPSIS

In F<lib/Your/Class.pm>:

 package Your::Class;
 use Class::Accessor::PackedString {
     # constructor => 'new',
     accessors => {
         foo => [0, ""],
         bar => [1,
     },
 };

In code that uses your class:

 use Your::Class;

 my $obj = Your::Class->new;
 $obj->foo(1980);
 $obj->bar(12);

or:

 my $obj = Your::Class->new(foo => 1, bar => 2);

C<$obj> is now:

 bless([1980, 12], "Your::Class");

To subclass, in F<lib/Your/Subclass.pm>:

 package Your::Subclass;
 our @ISA = qw(Your::Class);
 use Class::Accessor::Array {
     accessors => {
         baz => 2,
     },
 };


=head1 DESCRIPTION

This module is a builder for classes that use pack()-ed string as memory storage
backend. This is useful in situations where you need to create many thousands+
objects and want to reduce memory usage, because string-based objects are more
space-efficient than the commonly used hash-based objects. The downside is you
have to predeclare all the attributes of your class along with their types.
Another downside is speed, because there needs to be unpack()-ing and
re-pack()-ing everytime am attribute is accessed or set.


=head1 SEE ALSO

L<Class::Accessor::PackedString::Fields>

Class builders for array-based objects like L<Class::Accessor::Array> and
L<Class::Accessor::Array::Glob>.
