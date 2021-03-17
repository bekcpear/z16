#!/usr/bin/env bash
#

function e() {
  eval "local n=\${#${1}[@]}"
  echo "Nums: ${n}"
  for (( i = 0; i < ${n}; ++i )); do
    if [[ -z ${2} ]]; then
      echo Index:${i}
    fi
    eval "echo \${${1}[i]}"
  done
}

u=$(id -u)
if [[ ${u} != 0 ]]; then
  echo "Please run with root user!"
  exit 1
fi

pushd "${0%/*}"

testErr0=($(../z16.sh -c rootfs/etc/z16/z16rc load test0 2>&1))
if [[ ${#testErr0[@]} -ne 48 || ${testErr0[43]} != 'error]' ]]; then
  echo "Error: testErr0"
  e testErr0 1
  exit 1
fi

cp -R ./rootfs /

testErr1=($(../z16.sh -c rootfs/etc/z16/z16rc load test0 2>&1))
if [[ ${#testErr1[@]} -ne 30 || ${testErr1[28]} != "Instance" ]]; then
  echo "Error: testErr1"
  e testErr1 1
  exit 1
fi

if [[ "$(tree -augX /rootfs)" != "$(cat ./testtree/test0_tree.txt)" ]]; then
  echo "Error: load test0 error!"
  tree -aug /rootfs
  exit 1
fi

testErr2=($(../z16.sh -c rootfs/etc/z16/z16rc unload test0 2>&1))
if [[ ${#testErr2[@]} -ne 60 || ${testErr2[58]} != "Instance" ]]; then
  echo "Error: testErr2"
  e testErr2 1
  exit 1
fi

if [[ "$(tree -augX /rootfs)" != "$(cat ./testtree/test0_tree_u.txt)" ]]; then
  echo "Error: unload test0 error!"
  tree -augX /rootfs
  exit 1
fi

testErr3=($(../z16.sh -c rootfs/etc/z16/z16rc -v load test0 test1 2>&1))
if [[ ${#testErr3[@]} -ne 310 || ${testErr3[308]} != "Instances" ]]; then
  echo "Error: testErr3"
  e testErr3 1
  exit 1
fi

if [[ "$(tree -augX /rootfs)" != "$(cat ./testtree/test1_tree.txt)" ]]; then
  echo "Error: load test0 test1 error!"
  tree -augX /rootfs
  exit 1
fi

testErr4=($(../z16.sh -c rootfs/etc/z16/z16rc -v unload test0 test1 2>&1))
if [[ ${#testErr4[@]} -ne 138 || ${testErr4[136]} != "Instances" ]]; then
  echo "Error: testErr4"
  e testErr4 1
  exit 1
fi

if [[ "$(tree -augX /rootfs)" != "$(cat ./testtree/test1_tree_u.txt)" ]]; then
  echo "Error: unload test0 test1 error!"
  tree -augX /rootfs
  exit 1
fi

testErr5=($(../z16.sh -c rootfs/etc/z16/z16rc -v load test_testrhome 2>&1))
if [[ ${#testErr5[@]} -ne 10 || ${testErr5[8]} != "absolute" ]]; then
  echo "Error: testErr5"
  e testErr5 1
  exit 1
fi

useradd testr

testErr6=($(../z16.sh -c rootfs/etc/z16/z16rc -v load test_testrhome 2>&1))
if [[ ${#testErr6[@]} -ne 16 || ${testErr6[11]} != "error]" ]]; then
  echo "Error: testErr6"
  e testErr6 1
  exit 1
fi

mkdir -p /home/testr/tmp/test1
chown testr:testr /home/testr/tmp/test1

testErr7=($(../z16.sh -c rootfs/etc/z16/z16rc -v load test_testrhome 2>&1))
if [[ ${#testErr7[@]} -ne 213 || ${testErr7[211]} != "Instance" ]]; then
  echo "Error: testErr7"
  e testErr7 1
  exit 1
fi

if [[ "$(tree -augX /home/testr/tmp/test1)" != "$(cat ./testtree/testu_tree.txt)" ]]; then
  echo "Error: load test_testrhome error!"
  tree -augX /home/testr/tmp/test1
  exit 1
fi

testErr8=($(../z16.sh -c rootfs/etc/z16/z16rc -v unload test_testrhome 2>&1))
if [[ ${#testErr8[@]} -ne 86 || ${testErr8[84]} != "Instance" ]]; then
  echo "Error: testErr8"
  e testErr8 1
  exit 1
fi

if [[ "$(tree -augX /home/testr/tmp/test1)" != "$(cat ./testtree/testu_tree_u.txt)" ]]; then
  echo "Error: unload test_testrhome error!"
  tree -augX /home/testr/tmp/test1
  exit 1
fi

testErr9=($(../z16.sh -c rootfs/etc/z16/z16rc -v load test0 test1 test_testrhome 2>&1))
if [[ "$(tree -augX /rootfs)" != "$(cat ./testtree/testAr_tree.txt)" ]]; then
  echo "Error: load test0 test1 with test_testrhome error!"
  tree -augX /rootfs
  exit 1
fi
if [[ "$(tree -augX /home/testr/tmp/test1)" != "$(cat ./testtree/testu_tree.txt)" ]]; then
  echo "Error: load test_testrhome with test0 test1 error!"
  tree -augX /home/testr/tmp/test1
  exit 1
fi

testErr10=($(../z16.sh -c rootfs/etc/z16/z16rc -v unload test0 test1 test_testrhome 2>&1))
if [[ "$(tree -augX /rootfs)" != "$(cat ./testtree/testAr_tree_u.txt)" ]]; then
  echo "Error: unload test0 test1 with test_testrhome error!"
  tree -augX /rootfs
  exit 1
fi
if [[ "$(tree -augX /home/testr/tmp/test1)" != "$(cat ./testtree/testu_tree_u.txt)" ]]; then
  echo "Error: unload test_testrhome with test0 test1 error!"
  tree -augX /home/testr/tmp/test1
  exit 1
fi

useradd teste

testErr11=($(su teste -c "../z16.sh -c rootfs/etc/z16/z16rc -v load test_testrhome" 2>&1))
if [[ ${#testErr11[@]} -ne 23 || ${testErr11[21]} != "user!" ]]; then
  echo "Error: testErr11"
  e testErr11 1
  exit 1
fi

testErr12=($(../z16.sh -c rootfs/etc/z16/z16rc -pv load test1 test_testrhome 2>&1))
if [[ ${#testErr12[@]} -ne 401 || ${testErr12[399]} != "Instances" ]]; then
  echo "Error: testErr12"
  e testErr12 1
  exit 1
fi

mkdir -p /home/testr/.ssh
mkdir -p /home/teste/.ssh
cp ./testtree/testkey.pub /home/testr/.ssh/authorized_keys
cp ./testtree/testkey.pub /home/teste/.ssh/authorized_keys
sshdc=$(which sshd)
eval "${sshdc} -f ./testtree/sshd_config"
ssh -i ./testtree/testkey \
  -o 'StrictHostKeyChecking no' \
  -o 'ControlMaster auto' \
  -o 'ControlPath /tmp/z16_ssh_socket_%r@%h-%p' \
  -o 'ControlPersist 600' testr@127.0.0.1 'bash -c true'
ssh -i ./testtree/testkey \
  -o 'StrictHostKeyChecking no' \
  -o 'ControlMaster auto' \
  -o 'ControlPath /tmp/z16_ssh_socket_%r@%h-%p' \
  -o 'ControlPersist 600' teste@127.0.0.1 'bash -c true'

testErr13=($(../z16.sh -s teste@127.0.0.1 -c rootfs/etc/z16/z16rc -vk load test_testrhome 2>&1))
if [[ ${#testErr13[@]} != 67 || ${testErr13[64]} != "proper" ]]; then
  echo "Error: testErr13"
  e testErr13 1
  exit 1
fi

testErr14=($(../z16.sh -s testr@127.0.0.1 -c rootfs/etc/z16/z16rc -vk load test_testrhome 2>&1))
if [[ ${#testErr14[@]} != 334 || ${testErr14[332]} != "Instance" ]]; then
  echo "Error: testErr14"
  e testErr14 1
  exit 1
fi
if [[ "$(tree -augX /home/testr/tmp/test1)" != "$(cat ./testtree/testu_tree_ssh.txt)" ]]; then
  echo "Error: load test_testrhome by ssh error!"
  tree -augX /home/testr/tmp/test1
  exit 1
fi

testErr15=($(../z16.sh -s testr@127.0.0.1 -c rootfs/etc/z16/z16rc -vk unload test_testrhome 2>&1))
if [[ ${#testErr15[@]} != 95 || ${testErr15[93]} != "Instance" ]]; then
  echo "Error: testErr15"
  e testErr15 1
  exit 1
fi
if [[ "$(tree -augX /home/testr/tmp/test1)" != "$(cat ./testtree/testu_tree_u.txt)" ]]; then
  echo "Error: unload test_testrhome by ssh error!"
  tree -augX /home/testr/tmp/test1
  exit 1
fi


pkill ssh
pkill sshd
rm -rf /rootfs
userdel -r testr
userdel -r teste
popd
