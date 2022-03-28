FROM nfcore/base
LABEL authors="Nurlan Kerimov" \
      description="Docker image containing all requirements for leafcutter and regtools"

COPY environment_leafcutter.yml /
RUN conda env create -f /environment_leafcutter.yml python=2.7 && conda clean -a
ENV PATH /opt/conda/envs/rnaseq-leafcutter/bin:$PATH

RUN git clone https://github.com/davidaknowles/leafcutter

RUN for i in `find /leafcutter/scripts -name "*.py"`; do sed -i '1s/^/#! \/usr\/bin\/python2 \n/' $i; done
RUN chmod -R 777 /leafcutter/scripts/

ENV PATH $PATH:/leafcutter/scripts
