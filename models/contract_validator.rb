# frozen_string_literal: true

module Foresight
  module ContractValidator
    Rule = Struct.new(:required, :type, :allowed_values, :schema, :desc, keyword_init: true)

    # --- Schemas now use STRING KEYS exclusively for consistency with JSON ---

    ACCOUNT_SCHEMA = {
      'type' => Rule.new(required: true, type: String, allowed_values: ['TraditionalIRA', 'RothIRA', 'TaxableBrokerage', 'Cash']),
      'balance' => Rule.new(required: true, type: Numeric),
    }.freeze

    INCOME_SOURCE_SCHEMA = {
      'type' => Rule.new(required: true, type: String, allowed_values: ['Salary', 'Pension', 'SocialSecurity', 'SocialSecurityBenefit']),
    }.freeze

    GROWTH_ASSUMPTIONS_SCHEMA = {
      'traditional_ira' => Rule.new(required: true, type: Numeric),
      'roth_ira' => Rule.new(required: true, type: Numeric),
      'taxable' => Rule.new(required: true, type: Numeric),
      'cash' => Rule.new(required: true, type: Numeric),
    }.freeze

    REQUEST_SCHEMA = {
      'members' => Rule.new(required: true, type: Array),
      'filing_status' => Rule.new(required: true, type: String, allowed_values: ['mfj', 'single']),
      'accounts' => Rule.new(required: true, type: Array, schema: ACCOUNT_SCHEMA),
      'income_sources' => Rule.new(required: true, type: Array, schema: INCOME_SOURCE_SCHEMA),
      'growth_assumptions' => Rule.new(required: true, type: Hash, schema: GROWTH_ASSUMPTIONS_SCHEMA)
    }.freeze

    RESPONSE_SCHEMA = {
      'schema_version' => Rule.new(required: true, type: String),
      'mode' => Rule.new(required: true, type: String),
      'data' => Rule.new(required: true, type: Hash, schema: {
        'inputs' => Rule.new(required: true, type: Hash),
        'results' => Rule.new(required: true, type: Hash, schema: {
          '*' => Rule.new(required: true, type: Hash, schema: {
            'aggregate' => Rule.new(required: true, type: Hash),
            'yearly' => Rule.new(required: true, type: Array)
          })
        })
      })
    }.freeze

    # --- Public Methods ---
    def self.validate_request(params)
      string_keyed_params = deep_stringify_keys(params)
      errors = validate_hash(string_keyed_params, REQUEST_SCHEMA)
      { valid: errors.empty?, errors: errors }
    end

    def self.validate_response(response_hash)
      string_keyed_hash = deep_stringify_keys(response_hash)
      errors = validate_hash(string_keyed_hash, RESPONSE_SCHEMA)
      { valid: errors.empty?, errors: errors }
    end

    def self.generate_error_message(errors, payload)
      error_messages = errors.map do |error|
        field = error[:field]
        case error[:issue]
        when :missing
          "The required field '#{field}' is missing."
        when :invalid_type
          "The field '#{field}' has the wrong type. Expected #{error[:expected]}, but received #{error[:actual]}."
        when :invalid_value
          "The field '#{field}' has an invalid value. Allowed values are: #{error[:allowed].join(', ')}."
        else
          "An unknown error occurred with the field '#{field}'."
        end
      end
      "API Contract Error: #{error_messages.join(' ')}\nOffending Payload: #{payload.to_json}"
    end

    # --- Private Helper for Key Conversion ---
    private
    
    def self.deep_stringify_keys(object)
      case object
      when Hash
        object.each_with_object({}) do |(key, value), result|
          result[key.to_s] = deep_stringify_keys(value)
        end
      when Array
        object.map { |e| deep_stringify_keys(e) }
      else
        object
      end
    end


    # --- Private Validation Logic ---

    def self.validate_hash(data, schema, path = [])
      errors = []

      # Check for required keys defined in the schema
      schema.each do |key, rule|
        next if key == '*' # Handle wildcard separately
        current_path = path + [key]
        if rule.required && !data.key?(key)
          errors << { field: current_path.join('.'), issue: :missing }
        end
      end

      # Validate each key present in the data
      data.each do |key, value|
        rule = schema[key] || schema['*']
        next unless rule # Skip validation if no rule is defined for this key

        current_path = path + [key]

        # Type validation
        if rule.type && !value.is_a?(rule.type)
          errors << { field: current_path.join('.'), issue: :invalid_type, expected: rule.type, actual: value.class }
        end
        
        # Allowed values validation
        if rule.allowed_values && !rule.allowed_values.include?(value)
            errors << { field: current_path.join('.'), issue: :invalid_value, allowed: rule.allowed_values }
        end

        # Recursive validation for nested schemas
        if rule.schema
          if value.is_a?(Hash)
            errors.concat(validate_hash(value, rule.schema, current_path))
          elsif value.is_a?(Array)
            value.each_with_index do |item, index|
              errors.concat(validate_hash(item, rule.schema, current_path + [index.to_s])) if item.is_a?(Hash)
            end
          end
        end
      end
      
      # If a wildcard exists and the data is a hash that should not be empty
      if schema['*']&.required && data.is_a?(Hash) && data.empty?
          errors << { field: (path + ['*']).join('.'), issue: :missing }
      end

      errors
    end
  end
end
