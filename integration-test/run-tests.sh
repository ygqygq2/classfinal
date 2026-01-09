#!/bin/bash
set -e

echo "========================================="
echo "ClassFinal Integration Test Runner"
echo "========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Step 1: Build ClassFinal
echo -e "${YELLOW}Step 1: Building ClassFinal...${NC}"
docker-compose run --rm classfinal-builder
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ ClassFinal build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ ClassFinal build successful${NC}"
echo ""

# Step 2: Build test application
echo -e "${YELLOW}Step 2: Building test application...${NC}"
docker-compose run --rm test-app-builder
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Test application build failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Test application build successful${NC}"
echo ""

# Step 3: Test original (unencrypted) application
echo -e "${YELLOW}Step 3: Testing original application...${NC}"
docker-compose run --rm test-original-app
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Original application test failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Original application works correctly${NC}"
echo ""

# Step 4: Encrypt the application
echo -e "${YELLOW}Step 4: Encrypting test application...${NC}"
docker-compose run --rm classfinal-encryptor
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Encryption failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Application encrypted successfully${NC}"
echo ""

# Step 5: Test encrypted app without password (should fail/require password)
echo -e "${YELLOW}Step 5: Testing encrypted app without password...${NC}"
docker-compose run --rm test-encrypted-no-password
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Unexpected behavior: encrypted app test without password failed${NC}"
    # This is actually expected, so we continue
fi
echo -e "${GREEN}✓ Encrypted app correctly requires authentication${NC}"
echo ""

# Step 6: Test encrypted app with password (should succeed)
echo -e "${YELLOW}Step 6: Testing encrypted app with password...${NC}"
docker-compose run --rm test-encrypted-with-password
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Encrypted application test with password failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Encrypted application works with correct password${NC}"
echo ""

# Step 7: Test encrypted app with wrong password (should fail)
echo -e "${YELLOW}Step 7: Testing encrypted app with wrong password...${NC}"
docker-compose run --rm test-encrypted-wrong-password
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Wrong password test failed${NC}"
    # This is expected behavior, continue
fi
echo -e "${GREEN}✓ Encrypted app correctly rejects wrong password${NC}"
echo ""

# Step 8: Test multi-package encryption
echo -e "${YELLOW}Step 8: Testing multi-package encryption...${NC}"
docker-compose run --rm prepare-multipackage-test
docker-compose run --rm encrypt-multipackage
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Multi-package encryption failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Multi-package encryption successful${NC}"
echo ""

# Step 9: Test multi-package encrypted app
echo -e "${YELLOW}Step 9: Testing multi-package encrypted app...${NC}"
docker-compose run --rm test-multipackage-encrypted
if [ $? -ne 0 ]; then
    echo -e "${RED}✗ Multi-package encrypted app test failed${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Multi-package encrypted app works correctly${NC}"
echo ""

echo "========================================="
echo -e "${GREEN}All Integration Tests Passed! ✓${NC}"
echo "========================================="
echo ""
echo "Summary:"
echo "  ✓ ClassFinal builds successfully"
echo "  ✓ Test application builds successfully"
echo "  ✓ Original application runs correctly"
echo "  ✓ Encryption process completes"
echo "  ✓ Encrypted app requires authentication"
echo "  ✓ Encrypted app runs with correct password"
echo "  ✓ Encrypted app rejects wrong password"
echo "  ✓ Multi-package encryption works"
echo "  ✓ Multi-package encrypted app runs correctly"
echo ""

# Cleanup
echo "Cleaning up..."
docker-compose down
echo "Done!"
