ruby require 'rubygems'; require 'httparty'

function! TwitterSearch()
  let terms = input('Search Twitter for: ')
  ruby << RUBY
    terms = URI.encode(VIM::evaluate('terms'))
    terms.each do |r|
      tweet =  "@#{r} : #{r}"
      $curbuf.append($curbuf.length, tweet)
    end
RUBY
endfunction

function! OpenWindow()
  silent! exec 'vertical 10 new'
endfunction
