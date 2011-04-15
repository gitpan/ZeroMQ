#!/usr/bin/env perl
use strict;
use File::Spec;

# probe env vars first, as you may have wanted to override
# any auto-discoverable values
probe_envvars();
probe_pkgconfig();

sub probe_envvars {
    print "Probing environment variables:\n";
    my $home = $ENV{ZMQ_HOME};

    if (! $ENV{ZMQ_INCLUDES}) {
        my @incpaths;
        if ($ENV{INCLUDES}) {
            print " + Detected ZMQ_INCLUDES from INCLUDES (deprecated)...\n";
            push @incpaths, $ENV{INCLUDES};
        }

        if ($home) {
            my $zmq_inc = File::Spec->catdir( $home, 'include' );
            if (-e $zmq_inc) {
                print " + Detected ZMQ_INCLUDES from ZMQ_HOME...\n";
                push @incpaths, $zmq_inc;
            }
        }

        if (@incpaths) {
            $ENV{ZMQ_INCLUDES} = join ' ', @incpaths;
        }
    }

    if (! $ENV{ZMQ_H}) {
        if ($home) {
            my $zmq_header = File::Spec->catfile( $home, 'include', 'zmq.h' );
            if ( -f $zmq_header ) {
                print " + Detected ZMQ_H from ZMQ_HOME...\n";
                $ENV{ZMQ_H} = $zmq_header;
            }
        }
    }

    if (! $ENV{ZMQ_LIBS}) {
        my @libs;
        if ($ENV{LIBS}) {
            print " + Detected ZMQ_LIBS from LIBS (deprecated)...\n";
            push @libs, $ENV{LIBS};
        }

        if ($home) {
            my $zmq_lib = File::Spec->catdir( $home, 'lib' );
            if (-e $zmq_lib) {
                print " + Detected ZMQ_LIBS from ZMQ_HOME...\n";
                push @libs, sprintf '-L%s', $zmq_lib;
            }
        }

        if (@libs) {
            $ENV{ZMQ_LIBS} = join ' ', @libs;
        }
    }
}

# Note: At this point probe_envvars should have taken care merging
# deprecated INCLUDES/LIBS into %ENV
sub probe_pkgconfig {
    foreach my $pkg ( qw(libzmq zeromq2) ) {
        print "Probing $pkg via pkg-config ...\n";
        my $version = qx/pkg-config --modversion $pkg/;
        chomp $version;
        if (! $version) {
            print " - No $pkg found...\n";
            next;
        }

        print " + found $pkg $version\n";
        if (! $ENV{ZMQ_INCLUDES}) {
            if (my $cflags = qx/pkg-config --cflags-only-I $pkg/) {
                chomp $cflags;
                print " + Detected ZMQ_INCLUDES from pkg-config...\n";
                my @paths = map { s/^-I//; $_ } split /\s+/, $cflags;
                $ENV{ZMQ_INCLUDES} = join ' ', @paths;
                if (! $ENV{ZMQ_H}) {
                    foreach my $path (@paths) {
                        my $zmq_h = File::Spec->catfile($path, 'zmq.h');
                        if (-f $zmq_h) {
                            print " + Detected ZMQ_H from pkg-config...\n";
                            $ENV{ZMQ_H} = $zmq_h;
                            last;
                        }
                    }
                }
            }
        }

        if (! $ENV{ZMQ_LIBS}) {
            if (my $libs = qx/pkg-config --libs $pkg/) {
                chomp $libs;
                print " + Detected ZMQ_LIBS from pkg-config...\n";
                $ENV{ZMQ_LIBS} = $libs;
            }
        }

        last;
    }

}