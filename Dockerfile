FROM ruby
RUN date
MAINTAINER liumengxinfly@gmail.com
RUN date

RUN gem install jekyll rdiscount kramdown
RUN date
RUN apt-get update && apt-get install -y node python-pygments
RUN date
EXPOSE 4000

WORKDIR /src
CMD jekyll serve -H 0.0.0.0
ADD . /src
RUN date
