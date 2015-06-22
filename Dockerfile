ROM ruby
MAINTAINER liumengxinfly@gmail.com

RUN gem install jekyll rdiscount kramdown
RUN apt-get update && apt-get install -y node python-pygments
EXPOSE 4000

WORKDIR /src
ENTRYPOINT ["jekyll"]
CMD ["serve"]
ADD . /src
