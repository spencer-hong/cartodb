module Carto
  module Api
    class DbdirectCertificatesController < ::Api::ApplicationController
      include Carto::ControllerHelper
      extend Carto::DefaultRescueFroms

      ssl_required :list, :show, :create, :destroy


      before_action :load_user
      before_action :check_permissions

      setup_default_rescues

      def list
        dbdirect_certificates = @user.dbdirect_certificates
        certificates_info = dbdirect_certificates.map do |certificate|
          Carto::Api::DbdirectCertificatePresenter.new(certificate).to_poro
        end
        render_jsonp(certificates_info, 200)
      end

      def show
        dbdirect_certificate = Carto::DbdirectCertificate.find(params[:id])
        check_permissions_for_certificate(dbdirect_certificate)
        render_jsonp(Carto::Api::DbdirectCertificatePresenter.new(dbdirect_certificate).to_poro, 200)
      end

      def create
        validity_days = params[:validity].blank? ? Carto::DbdirectCertificate.default_validity : params[:validity].to_i
        data, cert = Carto::DbdirectCertificate.generate(
          user: @user,
          name: params[:name],
          passphrase: params[:pass],
          validity_days: validity_days,
          server_ca: params[:server_ca]
        )
        result = {
          id: cert.id,
          name: cert.name, # must include name since we may have changed or generated it
          client_key: data[:client_key],
          client_crt: data[:client_crt],
          server_ca: data[:server_ca]
        }
        # render_jsonp(result, 201)

        respond_to do |format|
          format.json do
            render_jsonp(result, 201)
          end
          format.zip do
            # TODO: generate zip from result; add generated README as well
            send_data(*zip_certificates(result, 201))
          end
        end

      end

      def destroy
        dbdirect_certificate = Carto::DbdirectCertificate.find(params[:id])
        check_permissions_for_certificate(dbdirect_certificate)
        dbdirect_certificate.destroy!
        render_jsonp(Carto::Api::DbdirectCertificatePresenter.new(dbdirect_certificate).to_poro, 200)
      end

      private

      def zip_certificates(result, status)
        # TODO: this shouldn't live here, should it?
        username = @user.username
        dbproxy_host = Cartodb.get_config(:dbdirect, 'pgproxy', 'host')
        dbproxy_port = Cartodb.get_config(:dbdirect, 'pgproxy', 'port')
        certificate_id = result[:id]
        certificate_name = result[:name]
        client_key = result[:client_key]
        client_crt = result[:client_crt]
        server_ca = result[:server_ca]
        # TODO: fetch README template, substitute variables
        readme = "Here are your files for certificate #{certificate_name} , blablabla, connecto to #{dbproxy_host}:#{dbproxy_port}"
        filename = "#{certificate_name}.zip" # TODO: include certificate_id too?
        # TODO: zip readme, client_key, client;crt, server_ca (if present)
        zip_data = readme
        [
          zip_data,
          type: "application/zip; charset=binary; header=present",
          disposition: "attachment; filename=#{filename}",
          status: status
        ]
      end

      def load_user
        @user = Carto::User.find(current_viewer.id)
      end

      def check_permissions
        # TODO: should the user be an organization owner?
        api_key = Carto::ApiKey.find_by_token(params["api_key"])
        if api_key.present?
          raise UnauthorizedError unless api_key&.master?
          raise UnauthorizedError unless api_key.user_id === @user.id
        end
        unless @user.has_feature_flag?('dbdirect')
          raise UnauthorizedError.new("DBDirect not enabled for user #{@user.username}")
        end
      end

      def check_permissions_for_certificate(dbdirect_certificate)
        raise UnauthorizedError unless dbdirect_certificate.user_id == @user.id
      end
    end
  end
end
