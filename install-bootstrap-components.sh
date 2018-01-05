tmpdir=`mktemp -d`
echo $tmpdir
for comp in $1/*.tar.xz; do
	c=`basename $comp .tar.xz`
	echo $c
	tar xvyf $comp -C $tmpdir
	bash $tmpdir/$c/install.sh --prefix=$2
	rm -rf $tmpdir/$c
done
rm -rf $tmpdir
