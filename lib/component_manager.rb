=begin
                  Arachni
  Copyright (c) 2010 Tasos "Zapotek" Laskos <tasos.laskos@gmail.com>

  This is free software; you can copy and distribute and modify
  this program under the term of the GPL v2.0 License
  (See LICENSE file for details)

=end

module Arachni

#
# Component Manager
#
# Handles modules, reports, path extrator modules, plug-ins, pretty much
# every modular aspect of the framework.
#
# It is usually extended to fill-in for system specific functionality.
#
# @author: Tasos "Zapotek" Laskos
#                                      <tasos.laskos@gmail.com>
#                                      <zapotek@segfault.gr>
# @version: 0.1
#
class ComponentManager < Hash

    #
    # The following are used by {#parse}:
    #    * '*' means all modules
    #    * module names prefixed with '-' will be excluded
    #
    WILDCARD = '*'
    EXCLUDE  = '-'

    #
    # @param    [String]    the path to the component library/folder
    # @param    [Module]    the parent module of the components
    #
    def initialize( lib, parent )
        @lib    = lib
        @parent = parent
    end

    #
    # Loads components
    #
    # @param [Array]    mods    array of names of components to load
    #
    def load( components )
        parse( components ).each {
            |component|
            self.[]( component )
        }
    end

    #
    # It parses the component array making sure that its structure is valid
    #
    # @param    [Array]     array of component names
    #
    def parse( components )
        unload = []
        load   = []

        components.each {
            |component|
            if component[0] == EXCLUDE
                component[0] = ''
                unload << component
            end
        }

        if( !components.include?( WILDCARD ) )

            avail_components  = available(  )

            components.each {
                |component|
                if( !avail_components.include?( component ) )
                      raise( Arachni::Exceptions::ComponentNotFound,
                          "Error: Component #{component} wasn't found." )
                end
            }

            # recon modules should be loaded before audit ones
            # and ls_available() honors that
            avail_components.map {
                |component|
                load << component if components.include?( component )
            }
        else
            available(  ).map {
                |component|
                load << component
            }
        end

        return load - unload
    end

    #
    # Returns a component class object by name, loading it on the fly need be.
    #
    # @param    [String]    name    component name
    #
    # @return   [Class]
    #
    def []( name )

        return fetch( name ) if include?( name )

        paths.each {
            |path|

            next if name != path_to_name( path )

            ::Kernel::load( path )
             self[name] = @parent.const_get( @parent.constants[-1] )
        }

        return fetch( name ) rescue nil
    end

    #
    # Returns array of available component names.
    #
    # @return    [Array]
    #
    def available
        components = []
        paths.each {
            |path|
            name = path_to_name( path )
            components << name
        }
        return components
    end

    #
    # Converts the name of a component to a file-path.
    #
    # @param    [String]    name    the name of the component
    #
    # @return   [String]
    #
    def name_to_path( name )
        paths.each {
            |path|
            return path if name == path_to_name( path )
        }
        return
    end

    #
    # Converts the path of a component to a component name.
    #
    # @param    [String]    path    the file-path of the component
    #
    # @return   [String]
    #
    def path_to_name( path )
        File.basename( path, '.rb' )
    end

    #
    # Returns the paths of all available components (excluding helper files).
    #
    # @return   [Array]
    #
    def paths
        cpaths = paths = Dir.glob( File.join( "#{@lib}**", "*.rb" ) )
        return paths.reject {
            |path|
            helper?( paths, path )
        }
    end

    private

    def helper?( paths, path )
        path = File.dirname( path )
        paths.each {
            |cpath|
            return true if path == File.dirname( cpath ) + '/' + path_to_name( path )
        }

        return false
    end

end

end
