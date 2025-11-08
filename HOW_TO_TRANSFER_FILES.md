# 🚀 How to Transfer Files from Your Local Machine to AWS EC2

You have the project files on your **local Windows machine**, but you need them on the **AWS EC2 instance**. Here are multiple methods:

---

## 📋 Quick Summary

**Best Methods** (Choose ONE):

1. ✅ **Git/GitHub** (Recommended - Professional & Easy)
2. ✅ **SCP/SFTP** (Direct Transfer - Fast)
3. ✅ **Copy-Paste** (Simple - For small files)

---

## Method 1: Git/GitHub (RECOMMENDED) ⭐

**Why?** Professional, version controlled, easy to update

### Step 1: Push to GitHub from Windows

```powershell
# Navigate to your project folder (on Windows)
cd D:\laragon\www\devops\ostad-2025\assignment\k8-monitoring

# Initialize git (if not already done)
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit - K8s Monitoring Project"

# Create repo on GitHub (via browser)
# Then connect and push:
git remote add origin https://github.com/YOUR_USERNAME/k8-monitoring.git
git branch -M main
git push -u origin main
```

### Step 2: Clone on EC2

```bash
# SSH to EC2
ssh -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>

# Install git (if needed)
sudo apt update
sudo apt install git -y

# Clone your repository
git clone https://github.com/YOUR_USERNAME/k8-monitoring.git

# Enter directory
cd k8-monitoring

# Now you have all files!
ls -la
```

### ✅ Advantages:

- Professional approach
- Version control
- Easy to update: just `git pull`
- Can submit GitHub repo as bonus

---

## Method 2: SCP (Secure Copy) - Direct Transfer

**Why?** Fast, secure, one command

### From Windows PowerShell:

```powershell
# Navigate to parent directory
cd D:\laragon\www\devops\ostad-2025\assignment

# Transfer entire folder to EC2
scp -i "C:\path\to\your-key.pem" -r k8-monitoring ubuntu@<EC2-PUBLIC-IP>:~/

# Example:
scp -i "C:\Users\YourName\Downloads\my-key.pem" -r k8-monitoring ubuntu@54.123.45.67:~/
```

**Explanation**:

- `-i "path\to\key.pem"` = Your SSH key
- `-r` = Recursive (copy entire folder)
- `k8-monitoring` = Source folder
- `ubuntu@<IP>:~/` = Destination (EC2 home directory)

### From Windows Git Bash (if installed):

```bash
scp -i /c/path/to/your-key.pem -r k8-monitoring ubuntu@<EC2-PUBLIC-IP>:~/
```

### Verify on EC2:

```bash
# SSH to EC2
ssh -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>

# Check files
ls -la ~/k8-monitoring
```

### ✅ Advantages:

- Very fast
- Single command
- No third-party services needed

---

## Method 3: WinSCP (GUI Tool) - User Friendly

**Why?** Visual interface, drag-and-drop

### Step 1: Download WinSCP

- Download from: https://winscp.net/
- Install on Windows

### Step 2: Connect to EC2

1. Open WinSCP
2. **File Protocol**: SFTP
3. **Host**: Your EC2 Public IP
4. **Port**: 22
5. **Username**: ubuntu
6. **Advanced** → **SSH** → **Authentication**
   - **Private key file**: Browse to your `.pem` file
   - WinSCP will convert it to `.ppk` if needed
7. Click **Login**

### Step 3: Transfer Files

1. Left panel = Your Windows files
2. Right panel = EC2 files
3. Navigate to `D:\laragon\www\devops\ostad-2025\assignment\k8-monitoring`
4. **Drag and drop** entire folder to EC2 home directory
5. Done!

### ✅ Advantages:

- Visual interface
- Easy for beginners
- Can browse files easily

---

## Method 4: Copy-Paste (For Small Files)

**Why?** No tools needed, works for individual files

### Step 1: Copy file content (Windows)

```powershell
# View file content
Get-Content scripts/01-ec2-setup.sh
```

### Step 2: Create file on EC2

```bash
# SSH to EC2
ssh -i "your-key.pem" ubuntu@<EC2-PUBLIC-IP>

# Create directory
mkdir -p k8-monitoring/scripts

# Create file with nano
nano k8-monitoring/scripts/01-ec2-setup.sh

# Paste content (Right-click or Shift+Insert)
# Save: Ctrl+O, Enter
# Exit: Ctrl+X
```

### ⚠️ Limitations:

- Tedious for many files
- Risk of copy errors
- Not recommended for 30+ files

---

## Method 5: Zip and Transfer

**Why?** Single file to transfer, faster for many files

### On Windows:

```powershell
# Compress folder
Compress-Archive -Path k8-monitoring -DestinationPath k8-monitoring.zip

# Transfer zip
scp -i "C:\path\to\your-key.pem" k8-monitoring.zip ubuntu@<EC2-PUBLIC-IP>:~/
```

### On EC2:

```bash
# Unzip
unzip k8-monitoring.zip

# Remove zip file
rm k8-monitoring.zip

# Check files
ls -la k8-monitoring/
```

### ✅ Advantages:

- Single file transfer
- Faster for many files
- Preserves structure

---

## 🎯 RECOMMENDED WORKFLOW (Best Practice)

### Use Git + GitHub:

**On Windows (One-time setup):**

```powershell
cd D:\laragon\www\devops\ostad-2025\assignment\k8-monitoring

# Create .gitignore if needed
@"
.DS_Store
*.swp
*.swo
*~
.vscode/
"@ | Out-File -FilePath .gitignore -Encoding utf8

# Initialize and push
git init
git add .
git commit -m "K8s Monitoring & Logging Dashboard - Module 7"
git remote add origin https://github.com/YOUR_USERNAME/k8-monitoring.git
git push -u origin main
```

**On EC2 (Every time you need files):**

```bash
# First time
git clone https://github.com/YOUR_USERNAME/k8-monitoring.git
cd k8-monitoring

# If you update files on Windows and push, just pull:
git pull origin main
```

---

## 📝 Complete Step-by-Step Example

### Scenario: Using SCP (Fastest for first-time)

**On Windows PowerShell:**

```powershell
# 1. Navigate to project parent folder
cd D:\laragon\www\devops\ostad-2025\assignment

# 2. Transfer to EC2 (replace with your details)
scp -i "C:\Users\YourName\Downloads\my-aws-key.pem" -r k8-monitoring ubuntu@54.123.45.67:~/

# You'll see output like:
# 01-ec2-setup.sh          100%  1234    1.2KB/s   00:01
# 02-install-minikube.sh   100%  2345    2.3KB/s   00:01
# ...
```

**On EC2 (via SSH):**

```bash
# 1. Connect
ssh -i "C:\Users\YourName\Downloads\my-aws-key.pem" ubuntu@54.123.45.67

# 2. Verify files arrived
ls -la ~/k8-monitoring

# Output should show:
# drwxr-xr-x  5 ubuntu ubuntu  4096 Nov  8 10:30 .
# drwxr-xr-x 10 ubuntu ubuntu  4096 Nov  8 10:30 ..
# -rw-r--r--  1 ubuntu ubuntu  8234 Nov  8 10:30 README.md
# drwxr-xr-x  2 ubuntu ubuntu  4096 Nov  8 10:30 scripts
# drwxr-xr-x  5 ubuntu ubuntu  4096 Nov  8 10:30 manifests
# ...

# 3. Navigate to project
cd k8-monitoring

# 4. Make scripts executable
chmod +x scripts/*.sh

# 5. Start deployment!
./scripts/01-ec2-setup.sh
```

---

## 🔧 Troubleshooting File Transfer

### Issue 1: "Permission denied (publickey)"

**Problem**: SSH key not recognized

**Solution**:

```powershell
# Windows - Set key permissions
icacls "C:\path\to\key.pem" /inheritance:r
icacls "C:\path\to\key.pem" /grant:r "%username%:R"

# Use full path to key
scp -i "C:\Users\YourName\Downloads\key.pem" -r k8-monitoring ubuntu@IP:~/
```

### Issue 2: "Connection refused"

**Problem**: Security group doesn't allow SSH

**Solution**:

1. Go to EC2 Console → Security Groups
2. Find your instance's security group
3. Add inbound rule: SSH (22) from Your IP
4. Try again

### Issue 3: Scripts don't execute

**Problem**: File permissions not set

**Solution**:

```bash
# On EC2
cd k8-monitoring
chmod +x scripts/*.sh

# Verify
ls -la scripts/
# Should show: -rwxr-xr-x (executable)
```

### Issue 4: Windows line endings cause errors

**Problem**: Scripts have Windows CRLF instead of Linux LF

**Solution**:

```bash
# On EC2, convert line endings
sudo apt install dos2unix -y

cd k8-monitoring/scripts
dos2unix *.sh

# Or use sed
sed -i 's/\r$//' *.sh
```

---

## 📊 Method Comparison

| Method           | Speed      | Difficulty | Best For              | Cost |
| ---------------- | ---------- | ---------- | --------------------- | ---- |
| **Git/GitHub**   | ⭐⭐⭐     | ⭐⭐       | Professional projects | Free |
| **SCP**          | ⭐⭐⭐⭐⭐ | ⭐⭐       | Quick transfers       | Free |
| **WinSCP**       | ⭐⭐⭐⭐   | ⭐         | Beginners             | Free |
| **Copy-Paste**   | ⭐         | ⭐         | 1-2 files             | Free |
| **Zip Transfer** | ⭐⭐⭐⭐   | ⭐⭐       | Many files            | Free |

---

## ✅ Recommended for This Assignment

### **Use Git/GitHub** because:

1. ✅ You can submit GitHub repo as bonus
2. ✅ Professional approach (looks good)
3. ✅ Easy to update if you change files
4. ✅ Instructors can review your code
5. ✅ You learn industry-standard workflow

### Quick GitHub Setup:

```powershell
# On Windows (in project folder)
git init
git add .
git commit -m "K8s Monitoring Project - Module 7"

# Create repo on github.com, then:
git remote add origin https://github.com/YOUR_USERNAME/k8-monitoring.git
git push -u origin main
```

```bash
# On EC2
git clone https://github.com/YOUR_USERNAME/k8-monitoring.git
cd k8-monitoring
chmod +x scripts/*.sh
./scripts/01-ec2-setup.sh
```

**Done! Now you can work! 🎉**

---

## 🎓 Summary

1. **Files are on Windows** → Need to get to EC2
2. **Best method**: Git/GitHub (professional)
3. **Fastest method**: SCP (direct transfer)
4. **Easiest method**: WinSCP (GUI)
5. **Once files are on EC2** → Make scripts executable → Run them!

**Next Step**: Choose a method and transfer your files! 🚀
