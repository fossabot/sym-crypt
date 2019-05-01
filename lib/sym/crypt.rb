require 'zlib'
require 'logger'

require 'sym/crypt/version'
require 'sym/crypt/errors'

require 'sym/crypt/configuration'

require 'sym/crypt/extensions/class_methods'
require 'sym/crypt/extensions/instance_methods'

#
# == Using Sym Library
#
# This library is a "wrapper" that allows you to take advantage of the
# symmetric encryption functionality provided by the {OpenSSL} gem (and the
# underlying C library). In order to use the library in your ruby classes, you
# should _include_ the module {Sym}.
#
# The including class is decorated with four instance methods from the
# module {Sym::Crypt::Extensions::InstanceMethods} and two class methods from
# {Sym::Crypt::Extensions::ClassMethods} – for specifics, please refer there.
#
# The two main instance methods are +#encr+ and +#decr+, which as the name
# implies, perform two-way symmetric encryption and decryption of any Ruby object
# that can be +marshaled+.
#
# Two additional instance methods +#encr_password+ and +#decr_password+ turn on
# password-based encryption, which actually uses a password to construct a 128-bit
# long private key, and then uses that in the encryption of the data.
# You could use them to encrypt data with a password instead of a randomly
# generated private key.
#
# Create a new key with +#create_private_key+ class method, which returns a new
# key every time it's called, or with +#private_key+ class method, which either
# assigns, or creates and caches the private key at a class level.
#
# == Example
#
#     require 'sym/crypt'
#
#     class TestClass
#       include Sym::Crypt
#       # read the key from environmant variable and assign to this class.
#       private_key ENV['PRIVATE_KEY']
#
#       def sensitive_value=(value)
#         @sensitive_value = encr(value, self.class.private_key)
#       end
#
#       def sensitive_value
#         decr(@sensitive_value, self.class.private_key)
#       end
#     end
#
# == Private Key
#
# They private key can be generated by +TestClass.create_private_key+
# which returns but does not store a new random 256-bit key.
#
# The key can be assigned and saved, or auto-generated and saved using the
# +#private_key+ method on the class that includes the +Sym+ module.
#
# Each class including the +Sym+ module would get their own +#private_key#
# class-instance variable accessor, and a possible value.
#

module Sym
  module Crypt
    NEW_CIPHER_PROC = ->(name) { ::OpenSSL::Cipher.new(name) }

    def self.included(klass)
      klass.instance_eval do
        include ::Sym::Crypt::Extensions::InstanceMethods
        extend ::Sym::Crypt::Extensions::ClassMethods
        class << self
          def private_key(value = nil)
            if value
              @private_key= value
            elsif @private_key
              @private_key
            else
              @private_key= self.create_private_key
            end
            @private_key
          end
        end
      end
    end

    class << self
      def config
        Sym::Crypt::Configuration.config
      end
    end
  end
end

Sym::Crypt::Configuration.configure do |config|
  # config.password_cipher = 'AES-128-CBC'
  # etc...
end

class Object
  unless self.methods.include?(:present?)
    def present?
      return false if self.nil?
      if self.is_a?(String)
        return false if self == ''
      end
      true
    end
  end
end

