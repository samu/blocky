module Abc
  class A
    def test
      puts %{blabla
        def
          puts 'abc'
        end
      }

      puts "yo" if true
    end
  end

  class B
    def blapp
    end
  end
end
