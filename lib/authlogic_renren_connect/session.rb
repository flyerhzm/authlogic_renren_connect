module AuthlogicRenrenConnect
  module Session
    def self.included(klass)
      klass.class_eval do
        extend Config
        include Methods
      end
    end

    module Config
      # Should the user be saved with our without validations?
      #
      # The default behavior is to save the user without validations and then
      # in an application specific interface ask for the additional user
      # details to make the user valid as renren just provides a renren id.
      #
      # This is useful if you do want to turn on user validations, maybe if you
      # just have renren connect as an additional authentication solution and
      # you already have valid users.
      #
      # * <tt>Default:</tt> true
      # * <tt>Accepts:</tt> Boolean
      def renren_valid_user(value = nil)
        rw_config(:renren_valid_user, value, false)
      end
      alias_method :renren_valid_user=, :renren_valid_user

      # What user field should be used for the renren UID?
      #
      # This is useful if you want to use a single field for multiple types of
      # alternate user IDs, e.g. one that handles both OpenID identifiers and
      # renren ids.
      #
      # * <tt>Default:</tt> :renren_uid
      # * <tt>Accepts:</tt> Symbol
      def renren_uid_field(value = nil)
        rw_config(:renren_uid_field, value, :renren_uid)
      end
      alias_method :renren_uid_field=, :renren_uid_field

      # What session key field should be used for the renren session key
      #
      #
      # * <tt>Default:</tt> :renren_session_key
      # * <tt>Accepts:</tt> Symbol
      def renren_session_key_field(value = nil)
        rw_config(:renren_session_key_field, value, :renren_session_key)
      end
      alias_method :renren_session_key_field=, :renren_session_key_field

      # Class representing renren users we want to authenticate against
      #
      # * <tt>Default:</tt> klass
      # * <tt>Accepts:</tt> Class
      def renren_user_class(value = nil)
        rw_config(:renren_user_class, value, klass)
      end
      alias_method :renren_user_class=, :renren_user_class

      # Should a new user creation be skipped if there is no user with given renren uid?
      #
      # The default behavior is not to skip (hence create new user). You may want to turn it on
      # if you want to try with different model.
      #
      # * <tt>Default:</tt> false
      # * <tt>Accepts:</tt> Boolean
      def renren_skip_new_user_creation(value = nil)
        rw_config(:renren_skip_new_user_creation, value, false)
      end
      alias_method :renren_skip_new_user_creation=, :renren_skip_new_user_creation
    end

    module Methods
      def self.included(klass)
        klass.class_eval do
          validate :validate_by_renren_connect, :if => :authenticating_with_renren_connect?
        end

        def credentials=(value)
          # TODO: Is there a nicer way to tell Authlogic that we don't have any credentials than this?
          values = [:renren_connect]
          super
        end
      end

      def validate_by_renren_connect
        renren_session = controller.renren_session
        self.attempted_record = renren_user_class.find(:first, :conditions => { renren_uid_field => renren_session.user.uid })

        if self.attempted_record
          self.attempted_record.send(:"#{renren_session_key_field}=", renren_session.session_key)
          self.attempted_record.save
        end

        unless self.attempted_record || renren_skip_new_user_creation
          begin
            # Get the user from renren and create a local user.
            #
            # We assign it after the call to new in case the attribute is protected.

            new_user = klass.new

            if klass == renren_user_class
              new_user.send(:"#{renren_uid_field}=", renren_session.user.uid)
              new_user.send(:"#{renren_session_key_field}=", renren_session.session_key)
            else
              new_user.send(:"build_#{renren_user_class.to_s.underscore}", :"#{renren_uid_field}" => renren_session.user.uid, :"#{renren_session_key_field}" => renren_session.session_key)
            end

            new_user.before_connect(renren_session) if new_user.respond_to?(:before_connect)

            self.attempted_record = new_user

            if renren_valid_user
              errors.add_to_base(
                I18n.t('error_messages.renren_user_creation_failed',
                       :default => 'There was a problem creating a new user ' +
                                   'for your Renren account')) unless self.attempted_record.valid?

              self.attempted_record = nil
            else
              self.attempted_record.save_with_validation(false)
            end
          rescue Renren::Session::SessionExpired
            errors.add_to_base(I18n.t('error_messages.renren_session_expired',
              :default => "Your Renren Connect session has expired, please reconnect."))
          end
        end
      end

      def authenticating_with_renren_connect?
        controller.set_renren_session
        attempted_record.nil? && errors.empty? && controller.renren_session
      end

      private
      def renren_valid_user
        self.class.renren_valid_user
      end

      def renren_uid_field
        self.class.renren_uid_field
      end

      def renren_session_key_field
        self.class.renren_session_key_field
      end

      def renren_user_class
        self.class.renren_user_class
      end

      def renren_skip_new_user_creation
        self.class.renren_skip_new_user_creation
      end
    end
  end
end
