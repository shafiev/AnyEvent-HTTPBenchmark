FROM        perl:5.32
MAINTAINER  Naim Shafiev sh.naim@yandex.ru

RUN curl -L http://cpanmin.us | perl - App::cpanminus
RUN cpanm AnyEvent::CacheDNS common::sense AnyEvent::HTTP

RUN git clone https://github.com/shafiev/AnyEvent-HTTPBenchmark
RUN cd AnyEvent-HTTPBenchmark 

WORKDIR AnyEvent-HTTPBenchmark
CMD ./benchmark.pl 