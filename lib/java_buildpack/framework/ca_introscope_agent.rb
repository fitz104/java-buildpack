# Encoding: utf-8
# Cloud Foundry Java Buildpack
# Copyright 2013 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'fileutils'
require 'java_buildpack/component/versioned_dependency_component'
require 'java_buildpack/framework'

module JavaBuildpack
  module Framework

    # Encapsulates the functionality for enabling zero-touch New Relic support.
    class CaIntroscopeAgent < JavaBuildpack::Component::VersionedDependencyComponent

      # (see JavaBuildpack::Component::BaseComponent#compile)
      def compile
        download_tar
        @droplet.copy_resources
      end

      # (see JavaBuildpack::Component::BaseComponent#release)
      def release
        @application.services.find_service(FILTER)['credentials']
        
        @droplet.java_opts
        .add_javaagent(@droplet.sandbox + 'Agent.jar')
        .add_system_property('com.wily.introscope.agentProfile', @droplet.sandbox + 'core/config/IntroscopeAgent.profile')
        .add_system_property('introscope.agent.enterprisemanager.transport.tcp.host.DEFAULT', credentials['host'])
        .add_system_property('introscope.agent.enterprisemanager.transport.tcp.port.DEFAULT', credentials['port'])
        .add_system_property('agent.name', agent_name)
      end

      protected

      # (see JavaBuildpack::Component::VersionedDependencyComponent#supports?)
      def supports?
        @application.services.one_service? FILTER, 'host', 'port'
      end

      private

      FILTER = /introscope/.freeze

      private_constant :FILTER

      def agent_name
        @application.details['application_name'] + "#{space_name}-#{instance_index}"
      end
      
      def instance_index
        "$(expr \"$VCAP_APPLICATION\" : '.*instance_index[\": ]*\"\\([0-9]\\+\\)\".*')"
      end

      def space_name
        "$(expr \"$VCAP_APPLICATION\" : '.*space_name[\": ]*\"\\([A-Za-z0-9]\\+\\)\".*')"
      end
      
    end

  end
end