# ENIGMA Imputation Protocol (as a container)

[![build](https://github.com/HippocampusGirl/ENIGMAImputationProtocol/actions/workflows/build.yml/badge.svg)](https://github.com/HippocampusGirl/ENIGMAImputationProtocol/actions/workflows/build.yml)

> This project is currently at an experimental stage and has not been validated
> by an experienced geneticist. Please use at your own risk.

With the advent of stricter data privacy laws in many jurisdictions, it has
become impossible for some researchers to use the
[Michigan Imputation Server](https://imputationserver.readthedocs.io/en/latest/)
to phase and impute genotype data. This project allows you to use the open
source code behind the server, and the rest of the
[ENIGMA Imputation Protocol](https://enigma.ini.usc.edu/wp-content/uploads/2020/02/ENIGMA-1KGP_p3v5-Cookbook_20170713.pdf),
on your local workstation or high-performance compute cluster.

## System requirements

This document assumes that you have either
[`Singularity`](https://sylabs.io/guides/3.7/user-guide/quick_start.html) or
[`Docker`](https://docs.docker.com/engine/install/) installed on your system.

## Usage

The container comes with all the software needed to run the imputation protocol.
You can either do this manually based on the official instructions, or use the
step-by-step guide below.

<ol>

<li>
<p>
You need to download the container file using one of the following commands.
This will use approximately one gigabyte of storage.
</p>
<table>
<thead>
  <tr>
    <th><b>Container platform</b></th>
    <th><b>Version</b></th>
    <th><b>Command</b></th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>Singularity</td>
    <td>3.x</td>
    <td><code>wget <a href="http://download.fmri.science/singularity/hippocampusgirl-enigma-imputation-protocol-latest.sif">http://download.fmri.science/singularity/hippocampusgirl-enigma-imputation-protocol-latest.sif</code></a></td>
  </tr>
  <tr>
    <td>Singularity</td>
    <td>2.x</td>
    <td><code>wget <a href="http://download.fmri.science/singularity/hippocampusgirl-enigma-imputation-protocol-latest.sif">http://download.fmri.science/singularity/hippocampusgirl-enigma-imputation-protocol-latest.simg</code></a></td>
  </tr>
  <tr>
    <td>Docker</td>
    <td></td>
    <td><code>docker pull hippocampusgirl/enigma-imputation-protocol:latest</code></td>
  </tr>
</tbody>
</table>
</li>

<li>
<p>
You will now need to create a working directory that can be used for 
intermediate files and outputs. This directory should be empty and should have
sufficient space available. We will store the path of the working directory in
the variable <code>working_directory</code>, and then create the new directory
and some subfolders.
</p>

```bash
export working_directory=/mnt/scratch/imputation
mkdir -p -v ${working_directory}/{raw,mds,qc}
```

</li>

<li>
<p>
Copy your raw data to the <code>raw</code> subfolder of the working directory. If you
have multiple <code>.bed</code> file sets that you want to process, copy them all.
</p>

```bash
cp -v my_sample.bed my_sample.bim my_sample.fam ${working_directory}/raw
```

</li>

<li>
<p>
Next, start an interactive shell inside the container using one of the
following commands.
</p>
<table>
<thead>
  <tr>
    <th><b>Container platform</b></th>
    <th><b>Command</b></th>
  </tr>
</thead>
<tbody>
  <tr>
    <td>Singularity</td>
    <td><code>singularity shell --bind ${working_directory}:/data hippocampusgirl-enigma-imputation-protocol-latest.sif</code></td>
  </tr>
  <tr>
    <td>Docker</td>
    <td>
        <code>docker run --interactive --tty --volume ${working_directory}:/data hippocampusgirl/enigma-imputation-protocol /bin/bash</code>
    </td>
  </tr>
</tbody>
</table>
</li>

<li>
<p>
Inside the container, we will first set up our local instance of the
<a href="https://imputationserver.readthedocs.io/en/latest/">Michigan Imputation Server</a>.
The following commands will start a <a href="https://hadoop.apache.org/">Hadoop</a>
instance on your computer, verify that it works, and then download the genome
reference that will be used for imputation (around 15 GB of data, so it may take a while).
</p>
<p>
If you encounter any warnings or messages while running these commands, do not worry. If
something went wrong, then you will see a clear error message that contains the word "error".
</p>

```bash
setup-hadoop --n-cores 8
setup-imputationserver
```

</li>

<li>
<p>
Next, go to <code>/data/mds</code>, and run <code>enigma-mds</code> for your <code>.bed</code>
file set. The script should now have created the files <code>mdsplot.pdf</code>
and  <code>HM3_b37mds2R.mds.csv</code>, which are summary statistics that you
will need to share with your working group.
</p>
<p>
If you have multiple <code>.bed</code> file sets, you should run the script in a
separate folder for each one. The script always outputs to the current folder.
</p>

```bash
cd /data/mds
enigma-mds --bfile ../raw/my_sample
```

</li>

<li>
<p>
Next, go to <code>/data/qc</code>, and run <code>enigma-qc</code> for your 
<code>.bed</code> file sets. This will drop any strand ambiguous SNPs and
screen for low MAF, missingness and HWE, then remove duplicate SNPs if
necessary, and finally convert the data to sorted <code>.vcf.gz</code>
format for imputation.
</p>
<p>
The script places intermediate files in the current folder, and the final
<code>.vcf.gz</code> files in <code>/data/input/my_sample</code> where
they can be accessed by the <code>imputationserver</code> script in the
next step.
</p>

```bash
cd /data/qc
enigma-qc --bfile ../raw/my_sample --study-name my_sample
```

</li>

<li>
<p>
Finally, run the <code>imputationserver</code> command for the correct sample population
(for example <code>eur</code> or <code>mixed</code>).
</p>

```bash
imputationserver --study-name my_sample --population eur
```

<p>
This process will likely take a few hours, and once it finishes for all your
<code>.bed</code> file sets, you can exit the container using the
<code>exit</code> command.
</p>
<p>
All outputs can be found in the working directory created earlier. The quality
control report can be found at
<code>${working_directory}/output/my_sample/qcreport/qcreport.html</code>, and
the imputation results at
<code>${working_directory}/output/my_sample/local</code>. The <code>.zip</code>
files are encrypted with the password <code>password</code>.
</p>
</li>

</ol>

## Troubleshooting

### Strand flips

> Error: More than 100 obvious strand flips have been detected. Please check
> strand. Imputation cannot be started!

If the `imputationserver` command fails with this error, then you will need to
resolve strand flips in your data. To automatically do that, the container comes
with the `checkflip` command, which is based on the
[RICOPILI](https://sites.google.com/a/broadinstitute.org/ricopili/) command of
the same name and [check-bim](https://www.well.ox.ac.uk/~wrayner/tools/).

```bash
checkflip --bfile ../raw/my_sample --population eur
```

The command will create a `.bed` file set at `../raw/my_sample.checkflip` which
will have all strand flips resolved.

### Velocity

> Job execution failed: Velocity could not be initialized!

You likely have bad permissions in your working directory. You can either try to
fix them, or start over with a fresh working directory.
