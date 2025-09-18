# frozen_string_literal: true

module Foresight
  # This module is the single source of truth for data contracts. It defines
  # the expected structure of payloads using robust, self-validating Rule objects.
  module ContractValidator
    # --- Schema Rule Definition ---
    Rule = Struct.new(:required, :type, :allowed_values, :schema, :desc, keyword_init: true)

    # --- Schema Definitions ---

    ACCOUNT_SCHEMA = {
      type: Rule.new(required: true, type: String, allowed_values: ['TraditionalIRA', 'RothIRA', 'TaxableBrokerage', 'Cash']),
      balance: Rule.new(required: true, type: Numeric),
    }.freeze

    INCOME_SOURCE_SCHEMA = {
      type: Rule.new(required: true, type: String, allowed_values: ['Salary', 'Pension', 'SocialSecurity', 'SocialSecurityBenefit']),
    }.freeze

    GROWTH_ASSUMPTIONS_SCHEMA = {
      traditional_ira: Rule.new(required: true, type: Numeric),
      roth_ira: Rule.new(required: true, type: Numeric),
      taxable: Rule.new(required: true, type: Numeric),
      cash: Rule.new(required: true, type: Numeric),
    }.freeze

    REQUEST_SCHEMA = {
      members: Rule.new(required: true, type: Array, desc: "A list of household members."),
      filing_status: Rule.new(required: true, type: String, allowed_values: ['mfj', 'single'], desc: "The tax filing status."),
      state: Rule.new(required: true, type: String, desc: "The state of residence (e.g., 'NY')."),
      years: Rule.new(required: true, type: Integer, desc: "The number of years to simulate."),
      start_year: Rule.new(required: true, type: Integer, desc: "The first year of the simulation."),
      accounts: Rule.new(required: true, type: Array, schema: ACCOUNT_SCHEMA, desc: "A list of financial accounts."),
      emergency_fund_floor: Rule.new(required: true, type: Numeric, desc: "The minimum cash balance to maintain."),
      income_sources: Rule.new(required: true, type: Array, schema: INCOME_SOURCE_SCHEMA, desc: "A list of income sources."),
      annual_expenses: Rule.new(required: true, type: Numeric, desc: "The estimated total annual spending."),
      strategies: Rule.new(required: true, type: Array, desc: "The list of strategies to simulate."),
      withdrawal_hierarchy: Rule.new(required: true, type: Array, desc: "The order of accounts for withdrawals."),
      inflation_rate: Rule.new(required: true, type: Numeric, desc: "The assumed annual inflation rate."),
      growth_assumptions: Rule.new(required: true, type: Hash, schema: GROWTH_ASSUMPTIONS_SCHEMA, desc: "A hash of growth rates for different account types.")
    }.freeze

    # A fully explicit schema for the data returned by the API.
    RESPONSE_SCHEMA = {
      schema_version: Rule.new(required: true, type: String),
      mode: Rule.new(required: true, type: String),
      data: Rule.new(required: true, type: Hash, schema: {
        inputs: Rule.new(required: true, type: Hash),
        results: Rule.new(required: true, type: Hash, schema: {
          # This now validates the structure of *each* strategy's results
          '*': Rule.new(required: true, type: Hash, schema: {
            aggregate: Rule.new(required: true, type: Hash),
            yearly: Rule.new(required: true, type: Array)
          })
        })
      })
    }.freeze

    def self.validate_request(params)
      validate(params, REQUEST_SCHEMA)
    end

    def self.validate_response(response_hash)
      validate(response_hash, RESPONSE_SCHEMA)
    end

    def self.generate_error_message(errors, payload)
      error_messages = errors.map do |error|
        field = error[:field]
        rule = error[:rule]
        case error[:issue]
        when :missing
          "The required field '#{field}' is missing. #{rule.desc}"
        when :invalid_type
          "The field '#{field}' has the wrong type. Expected #{rule.type}, but received #{error[:value].class}."
        when :invalid_value
          "The field '#{field}' has an invalid value ('#{error[:value]}'). It must be one of: #{rule.allowed_values.join(', ')}."
        else
          "An unknown error occurred with the field '#{field}'."
        end
      end
      "API Contract Error: #{error_messages.join(' ')}\nOffending Payload: #{payload.to_json}"
    end

    private

    def self.validate(data, schema, path = [])
      errors = []

      # Handle wildcard schemas (for validating each key in a hash)
      if (wildcard_rule = schema['*'])
        data.each do |key, value|
          errors.concat(validate(value, wildcard_rule.schema, path + [key])[:errors])
        end
        return { valid: errors.empty?, errors: errors }
      end

      schema.each do |field, rule|
        current_path = path + [field]
        
        if rule.required && !data.key?(field)
          errors << { field: current_path.join('.'), issue: :missing, rule: rule }
          next
        end
        
        next unless data.key?(field)
        
        value = data[field]

        if rule.type && !value.is_a?(rule.type)
          errors << { field: current_path.join('.'), issue: :invalid_type, value: value, rule: rule }
          next
        end

        if rule.allowed_values && !rule.allowed_values.include?(value)
          errors << { field: current_path.join('.'), issue: :invalid_value, value: value, rule: rule }
        end
        
        if rule.schema
          case value
          when Hash
            errors.concat(validate(value, rule.schema, current_path)[:errors])
          when Array
            value.each_with_index do |item, index|
              errors.concat(validate(item, rule.schema, current_path + [index.to_s])[:errors]) if item.is_a?(Hash)
            end
          end
        end
      end

      { valid: errors.empty?, errors: errors }
    end
  end
end
