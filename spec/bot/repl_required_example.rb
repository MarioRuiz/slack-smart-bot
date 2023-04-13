############################################
# 1. Create a new file
# 2. Paste the code below
# 3. Save the file as "test.rb"
# 4. Run the command "ruby test.rb"
############################################
module Operations

    ############################
    # operationId: Operations_List, method: get
    # summary: Describes the available operations
    # description:
    #     Lists all of the available Rest API operations
    # parameters description:
    #    api-version: (string) (required) The API version to use for this operation.
    #    uno: (integer) (optional) First
    #    dos: (integer) (optional) Second
    #    tres: (integer) (optional) Third
    #    cuatro: (integer) (optional) Fourth
    #    cinco: (integer) (optional) Fifth
    #    seis: (integer) (optional) Sixth
    #    siete: (integer) (optional) Seventh
    #    ocho: (integer) (optional) Eighth
    #    lobo: (string) (required) blah and blah and blah
    #    mando: (string) (required) blah and blah and blah
    ############################
    def self.list(giveme, opt='', api_version: API_VERSION, uno: 1, dos: 2, 
                   tres: 3, cuatro: 4, cinco: 5,
                   seis: 6, siete: 7, ocho: 8, lobo:, mando:)
      {
        name: "Operations.list",
        path: "/providers/operations?api-version=#{api_version}&",
        method: :get,
        responses: {
          '200': {
            message: "OK",
            data: {
              value: [] }
            }
        }
      }
    end
  
    # operationId: Operations_List, method: get
    # summary: Describes the Resource Provider
    # description:
    #     Lists all of the available Rest API operations
    # parameters description:
    #    api-version: (string) (required) The API version to use for this operation.
    def self.list_async(api_version: API_VERSION)
      {}
    end
  
    # operationId: Operations_Get, method: get
    # summary: Describes the Resource Provider
    # description:
    #     Lists all of the available Rest API operations
    # parameters description:
    #    api-version: (string) (required) The API version to use for this operation.
    def self.get(api_version: API_VERSION)
      {}
    end
  
    def self.print(value, api_version: API_VERSION, love: true, number: 0)
      {}
    end

    # operationId: Operations_Get, method: get
    # summary: Describes the Resource Provider
    # description:
    #     Lists all of the available Rest API operations
    def self.no_parameters
      {}
    end

    # operationId: Operations_Get, method: get
    # summary: Describes the Resource Provider
    # description:
    #     Lists all of the available Rest API operations
    # parameters description:
    #    api-version: (string) (required) The API version to use for this operation.
    #   love: (boolean) (optional) The API version to use for this operation.
    #   number: (integer) (optional) The API version to use for this operation.
    def self.no_parenthesis api_version: API_VERSION, love: true, number: 0
      {}
    end

    module Two

        # operationId: Operations_List, method: get
        # summary: Describes the Resource Provider
        # description:
        #     Lists all of the available Rest API operations
        # parameters description:
        #    api-version: (string) (required) The API version to use for this operation.
        def self.love(api_version: API_VERSION)
          {
            name: "Operations::Two.love",
            path: "/providers/operations/2?api-version=#{api_version}&",
            method: :get
          }
        end

        # operationId: Operations_List, method: get
        # summary: Describes the Resource Provider
        # description:
        #     Lists all of the available Rest API operations Love2
        # parameters description:
        #    api-version: (string) (required) The API version to use for this operation.
        def love2(api_version: API_VERSION)
          {
            name: "Operations::Two.love2",
            path: "/providers/operations/2?api-version=#{api_version}&",
            method: :get
          }
        end
    end
  
end


# some text to explain the code for SMExample
class SMExample

  # some text to explain the initialize method
  def initialize
    @name = 'SMExample'
  end

  # some text to explain the print method
  def print
      puts @name
  end
  # some text to explain the love method
  def self.love
    puts 'love'
  end
end

#example for method
def love_print(value, api_version: API_VERSION, love: true, number: 0)    
  puts 'love'
end
