# Synchronizes the file system for a project with the group structure in its xCode project.
#
# Author:: Doug Togno
# Copyright:: Copyright (C) 2013 Doug Togno
# License:: MIT
#

# :nodoc: namespace
module ZergXcode::Plugins

  class Syncfs
    require "fileutils"
      
    def help
      {:short => 'Synchronizes the file system of a project with the group structure in its xCode project',
       :long =>  'Creates directories then moves and copies files to match the group structure of an xCode project, the project file is updated to point at the new files and paths' }
        #Usage: syncfs [project file path]
    end

    def run(args)
      #Shift the pwd to the project directory if we are not already there
      path = args[0].rpartition('/')

      if(path[0].length > 0)
        Dir.chdir(path[0])  
      end

      sync_fs_with_project(path[2])
    end

    def sync_fs_with_project(project_name)
      proj = ZergXcode.load(project_name)

      #Check writing to the project is ok
      proj.save!

      file_corrections = []
      group_corrections = []
      project_root = proj['projectRoot'].empty? ? '' : proj['projectRoot']
      FileVisitor.visit proj['mainGroup'], project_root, "/", file_corrections, group_corrections
          
      file_corrections.map do |file| 
        #Create directory structure for the file, even if the file is skipped due to already existing this is important to keep groups in check
        FileUtils.mkdir_p  Dir.pwd + file[:projpath]
        if(!File.exists?(Dir.pwd + file[:projpath] + file[:filename]))
          #If the file exists outside the project dir copy it in, otherwise move it
          if(!File.expand_path(Dir.pwd + file[:filepath]).start_with?(Dir.pwd))

              FileUtils.cp File.expand_path(Dir.pwd + file[:filepath]), Dir.pwd + file[:projpath] + file[:filename]
              #Correct file graph
              file[:object]._attr_hash.delete('name')
              file[:object]._attr_hash['path'] = file[:filename] 
              else
              FileUtils.mv Dir.pwd + file[:filepath], Dir.pwd + file[:projpath] + file[:filename]
              #Correct file graph
              file[:object]._attr_hash.delete('name')
              file[:object]._attr_hash['path'] = file[:filename]
              end

        else
          puts "WARNING: File '" + file[:filename] + "' already exists at " + file[:projpath] + ' and will be skipped'
        end
      end

      group_corrections.map do |folder|

        if File.exists?(Dir.pwd + folder[:projpath])
          #If a directory for a given group path exists, correct the group to point at it
          folder[:object]._attr_hash['path'] = folder[:object]['name']
          folder[:object]._attr_hash.delete('name')
        end
      
      end
      
      #Complete
      proj.save!  
    end

    # Container for the visitor that lists all files in a project, leveraged from pbx_projects visitor of the same name
    module FileVisitor

      def self.visit(object, root_path, xcode_path, file_corrections, group_corrections)
        case object.isa
        when :PBXVariantGroup
          #TODO: These are used with localised files, for now they are ignored
        when :PBXGroup
          visit_group(object, root_path, xcode_path, file_corrections, group_corrections)
        when :PBXFileReference
          visit_file(object, root_path, xcode_path, file_corrections)
        end
      end

      def self.visit_group(group, root_path, xcode_path, file_corrections, group_corrections)
        path = merge_path(root_path, group['sourceTree'], group)

        if(group['name'] != nil)
          proj_path = xcode_path + group['name'] + "/"
          #A non-nil name indicates we may have to correct the groups path
          group_corrections << { :object => group, :filepath =>path, :projpath => proj_path }
        elsif(group['path'] != nil)
          proj_path = xcode_path + group['path'] + "/"
        else
          proj_path = xcode_path
        end

        group['children'].each do |child|
          visit child, path, proj_path, file_corrections, group_corrections
        end
      end

      def self.visit_file(file, root_path, xcode_path, file_corrections)
        if(file['sourceTree'] == "<group>")
          path = merge_path(root_path, file['sourceTree'], file)
          if(file['name'])
            file_name = file['name']
          else
            file_name = file['path']
          end

          #Don't move around other project files
          if((path != xcode_path + file_name) && file['lastKnownFileType'] != 'wrapper.pb-project')
            file_corrections << { :filepath => path, :projpath => xcode_path, :filename => file_name, :object => file } 
          end
        end
      end

      def self.merge_path(old_path, source_tree, object)
        case source_tree
        when '<group>'
          base_path = old_path
        else
          base_path = source_tree
        end

        if object['path']
          path = File.join(base_path, object['path'])
        else
          path = old_path
        end
        return path
      end
    end
  end
end 
