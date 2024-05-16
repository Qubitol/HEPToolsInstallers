#!/bin/bash

set_environment () {

  echo " Set environment variables"

  # Here, define your installation paths, versions etc.
  gccversion="$(gcc -dumpversion)"
  BOOST="$1"
  INSTALLD="$2"
  VERSION="$3"
  TARBALL="$4"
  CXXFLAGS="$5"
  LOCAL=$INSTALLD

  # set SLC5 platform name:
  LCG_PLATFORM=i686
  if [[ "$(uname -m)" == "x86_64" ]] ; then
    LCG_PLATFORM=x86_64
  fi

  unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    MSYS_NT*)   machine=Git;;
    *)          machine="UNKNOWN:${unameOut}"
esac

}

run () {

  workd=$(pwd)

  echo " Unpack LHAPDF"
  tar xvzf $TARBALL

  echo "running on ${machine}"

  echo " Enter LHAPDF6 directory"
  cd LHAPDF-${VERSION}/

  if [[ $machine == "Mac" ]] ; then
      sed -i.bckp 's/LINKFORSHARED/PY_CFLAGS/g' ./configure
      diff configure.bckp configure
  fi

  echo " Configure LHAPDF: $CXXFLAGS"
  

  LIBRARY_PATH=$LD_LIBRARY_PATH ./configure CXXFLAGS="$CXXFLAGS" --prefix=$LOCAL --bindir=$LOCAL/bin --datadir=$LOCAL/share --libdir=$LOCAL/lib --enable-static
  echo " Compile LHAPDF6"
  LIBRARY_PATH=$LD_LIBRARY_PATH make

  echo " Install LHAPDF6"
  LIBRARY_PATH=$LD_LIBRARY_PATH make install

  echo "copy index and conf file"
  cd $INSTALLD
  index="$(find . -name 'pdfsets.index')"
  cp $index $INSTALLD/share/LHAPDF/
  conf="$(find . -name 'lhapdf.conf')"
  cp $conf $INSTALLD/share/LHAPDF/

#  echo " Get LHAPDF sets"
#  cd $INSTALLD/share/LHAPDF
#  wget --no-parent --recursive --level=1 -e robots=off -A.tar.gz -nd https://www.hepforge.org/archive/lhapdf/pdfsets/6.1/
#  ls -1 *.tar.gz | while read line; do tar xvfz $line; done

# Get default NNPDF for MG5aMC
  if [ -f $LOCAL/bin/lhapdf ]; then
      cd $INSTALLD/share/LHAPDF;
      weblo="http://lhapdfsets.web.cern.ch/lhapdfsets/current/NNPDF23_lo_as_0130_qed.tar.gz"
      webnlo="http://lhapdfsets.web.cern.ch/lhapdfsets/current/NNPDF23_nlo_as_0119_qed.tar.gz"
      if ! command -v wget &> /dev/null
      then
         curl -o NNPDF23_lo_as_0130_qed.tar.gz $weblo
         curl -o NNPDF23_nlo_as_0119_qed.tar.gz $webnlo
      else
         wget $weblo -O NNPDF23_lo_as_0130_qed.tar.gz
         wget $webnlo -O NNPDF23_nlo_as_0119_qed.tar.gz
      fi

      tar xfz  NNPDF23_lo_as_0130_qed.tar.gz
      tar xfz NNPDF23_nlo_as_0119_qed.tar.gz
  else
      exit 1
  fi
  echo " Finished LHAPDF6 installation"
  cd $workd
  ls $LOCAL/bin

}

set_environment "$@"
run "$@"

