FROM genepi/imputationserver:v1.5.7

RUN mkdir -p -v /localdata/mds && \
    for file_name in HM3_b37.bed HM3_b37.bim HM3_b37.fam; do \
        wget -qO - http://genepi.qimr.edu.au/staff/sarahMe/enigma/MDS/${file_name}.gz | gunzip > /localdata/mds/${file_name}; \
    done

RUN (apt-get update || exit 0) && \
    apt-get install -y "vcftools" && \
    apt-get clean && \
    apt-get purge && \
    wget -qO /tmp/plink_linux.zip "https://s3.amazonaws.com/plink1-assets/plink_linux_x86_64_20210606.zip" && \
    unzip /tmp/plink_linux.zip plink -d /usr/local/bin && \
    wget -qO /tmp/plink2_linux.zip "https://s3.amazonaws.com/plink2-assets/plink2_linux_x86_64_20210608.zip" && \
    unzip /tmp/plink2_linux.zip plink2 -d /usr/local/bin && \
    wget -qO /tmp/miniconda.sh "https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh" && \
    bash /tmp/miniconda.sh -b -p /usr/local/miniconda && \
    wget -qO /tmp/calibrate.tar.gz "https://cran.r-project.org/src/contrib/Archive/calibrate/calibrate_1.7.2.tar.gz" && \
    R CMD INSTALL /tmp/calibrate.tar.gz && \
    rm -rf /var/lib/apt/lists/* /tmp/*; sync

ENV PATH="/usr/local/miniconda/bin:$PATH" \
    CPATH="/usr/local/miniconda/include:$CPATH" \
    LANG="C.UTF-8" \
    LC_ALL="C.UTF-8"

RUN conda install -y python=3.9; sync && \
    chmod -R a+rX /usr/local/miniconda; sync && \
    chmod +x /usr/local/miniconda/bin/*; sync && \
    conda clean -y --all && sync && \
    rm -rf ~/.conda ~/.cache/pip/*; sync

COPY cloudgene-override/* /opt/cloudgene/
COPY bin/* /usr/local/bin/

CMD ["/bin/bash"]
